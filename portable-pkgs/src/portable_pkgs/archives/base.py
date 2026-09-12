"""Format-independent archive metadata and the open archive interface."""

from abc import ABC, abstractmethod
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

from ..models import FrozenModel, PackageError

ArchiveMemberKind = Literal["file", "directory", "symlink", "hardlink", "other"]


class ArchiveMember(FrozenModel):
    """Original archive metadata, including names unsafe to install."""

    path: str
    kind: ArchiveMemberKind
    mode: int
    link_target: str | None = None
    size: int


@dataclass(frozen=True)
class InstalledMember:
    member: ArchiveMember
    path: str


def assert_safe_member(path: str) -> None:
    if (
        Path(path).is_absolute()
        or ".." in Path(path).parts
        or "\\" in path
        or "\x00" in path
    ):
        raise PackageError(f"unsafe archive path: {path}")


class Archive(ABC):
    """An open archive. Use open_archive to own its lifetime and error boundary."""

    @abstractmethod
    def members(self) -> tuple[ArchiveMember, ...]:
        """Describe members without extracting anything."""

    def extract_member(self, member: str, destination: Path) -> Path:
        """Extract a selected member using the format's native semantics."""
        assert_safe_member(member)
        try:
            self._extract_member(member, destination)
        except KeyError as error:
            raise PackageError(f"archive member not found: {member}") from error
        return destination / member

    @abstractmethod
    def _extract_member(self, member: str, destination: Path) -> None:
        pass

    @abstractmethod
    def extract_tree(
        self, entries: Sequence[InstalledMember], destination: Path
    ) -> None:
        """Extract a bundle tree after shared installation policy validates it."""
