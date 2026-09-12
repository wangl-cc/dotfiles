"""Manifest persistence and coordinated package-source saves."""

import fcntl
import os
import stat
import tempfile
from collections.abc import Iterator
from contextlib import AbstractContextManager, contextmanager
from dataclasses import dataclass
from pathlib import Path

import yaml
from pydantic import TypeAdapter

from .models import PackageError, PortableManifest
from .sources import PackageSources

DEFAULT_MANIFEST_PATH = (
    Path(__file__).resolve().parents[3] / "home/.chezmoidata/portable-pkgs.yaml"
)
MANIFEST_DOCUMENT = TypeAdapter(dict[str, object])


def manifest_path() -> Path:
    return Path(
        os.environ.get("PORTABLE_PKGS_MANIFEST", DEFAULT_MANIFEST_PATH)
    ).expanduser()


def atomic_write_text(path: Path, content: str) -> None:
    """Replace one source file without exposing a partial write.

    Staging stays on the destination filesystem. A failed multi-file save is
    reconciled from the unchanged manifest on retry; it is not a transaction
    with concurrent chezmoi readers or other manifest writers.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o644
    with tempfile.TemporaryDirectory(
        prefix=".portable-pkgs-write-", dir=path.parent
    ) as directory:
        staged = Path(directory) / "content"
        staged.write_text(content)
        staged.chmod(mode)
        staged.replace(path)


@dataclass(frozen=True)
class ManifestFile:
    path: Path

    @contextmanager
    def lock(self) -> Iterator[None]:
        # Keep a stable inode: unlinking a lock file lets another writer bypass
        # a process that has already opened it. OS release also handles crashes.
        try:
            path = self.path.resolve()
            with path.with_name(f".{path.name}.lock").open("a") as lock:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                except BlockingIOError as error:
                    raise PackageError(
                        f"another portable-pkgs command is modifying {path}"
                    ) from error
                try:
                    yield
                finally:
                    fcntl.flock(lock, fcntl.LOCK_UN)
        except OSError as error:
            raise PackageError(f"lock manifest {self.path}: {error}") from error

    def load(self) -> PortableManifest:
        try:
            data = MANIFEST_DOCUMENT.validate_python(
                yaml.safe_load(self.path.read_text()) or {}
            )
            return PortableManifest.model_validate(data.get("portable_pkgs"))
        except (OSError, ValueError, yaml.YAMLError) as error:
            raise PackageError(f"read manifest {self.path}: {error}") from error

    def save(self, content: str) -> None:
        """Write a fully serialized manifest without managing package sources."""
        try:
            atomic_write_text(self.path, content)
        except OSError as error:
            raise PackageError(f"write manifest {self.path}: {error}") from error


@dataclass(frozen=True)
class PackageStore:
    """Coordinate a package manifest with its generated chezmoi sources.

    The caller holds the lock through load, resolution, verification, and save.
    All sources are preflighted before changes; the manifest is written last so
    retrying the same operation can recover a partially applied source plan.
    Obsolete generated sources are unlinked rather than moved aside: their
    content is reproducible and version control already tracks them.
    """

    path: Path

    def lock(self) -> AbstractContextManager[None]:
        return ManifestFile(self.path).lock()

    def load(self) -> PortableManifest:
        return ManifestFile(self.path).load()

    def save(self, manifest: PortableManifest) -> None:
        try:
            before = self.load() if self.path.exists() else None
            changes = PackageSources(self.path).plan(before, manifest)
            content = yaml.safe_dump(
                {"portable_pkgs": manifest.model_dump(exclude_none=True, mode="json")},
                sort_keys=False,
                width=1000,
            )
            for path, source in changes.items():
                if source is None:
                    path.unlink()
                else:
                    atomic_write_text(path, source)
            ManifestFile(self.path).save(content)
        except (OSError, ValueError, yaml.YAMLError) as error:
            raise PackageError(f"save packages {self.path}: {error}") from error
