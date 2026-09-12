"""ZIP member interpretation, permission metadata, and extraction."""

import shutil
import stat
import zipfile
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from pathlib import Path

from .base import Archive, ArchiveMember, ArchiveMemberKind, InstalledMember


class ZipArchive(Archive):
    def __init__(self, archive: zipfile.ZipFile) -> None:
        self._archive = archive

    @classmethod
    @contextmanager
    def open(cls, path: Path) -> Iterator["ZipArchive"]:
        with zipfile.ZipFile(path) as archive:
            yield cls(archive)

    @staticmethod
    def member_kind(member: zipfile.ZipInfo) -> ArchiveMemberKind:
        if member.is_dir():
            return "directory"
        mode = member.external_attr >> 16
        if stat.S_ISLNK(mode):
            return "symlink"
        if stat.S_IFMT(mode) in (0, stat.S_IFREG):
            return "file"
        return "other"

    def describe(self, member: zipfile.ZipInfo) -> ArchiveMember:
        kind = self.member_kind(member)
        link = self._archive.read(member).decode("utf-8") if kind == "symlink" else None
        return ArchiveMember(
            path=member.filename,
            kind=kind,
            mode=stat.S_IMODE(member.external_attr >> 16),
            link_target=link,
            size=member.file_size,
        )

    def members(self) -> tuple[ArchiveMember, ...]:
        return tuple(self.describe(member) for member in self._archive.infolist())

    def _extract_member(self, member: str, destination: Path) -> None:
        self._archive.extract(member, destination)

    def extract_tree(
        self, entries: Sequence[InstalledMember], destination: Path
    ) -> None:
        for entry in entries:
            self._install(entry, destination)

    def _install(self, entry: InstalledMember, destination: Path) -> None:
        path = destination / entry.path
        path.parent.mkdir(parents=True, exist_ok=True)
        member = entry.member
        if member.kind == "directory":
            path.mkdir(exist_ok=True)
            return
        if member.link_target is not None:
            path.symlink_to(member.link_target)
            return
        original = self._archive.getinfo(member.path)
        with self._archive.open(original) as source, path.open("wb") as output:
            shutil.copyfileobj(source, output)
        # Match ZIP's historical default when no Unix metadata was supplied.
        mode = member.mode if original.external_attr >> 16 else 0o644
        path.chmod(mode)
