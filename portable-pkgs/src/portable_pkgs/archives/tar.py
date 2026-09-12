"""Tar member interpretation and native extraction."""

import copy
import stat
import tarfile
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from pathlib import Path

from .base import Archive, ArchiveMember, ArchiveMemberKind, InstalledMember


class TarArchive(Archive):
    def __init__(self, archive: tarfile.TarFile) -> None:
        self._archive = archive

    @classmethod
    @contextmanager
    def open(cls, path: Path) -> Iterator["TarArchive"]:
        with tarfile.open(path) as archive:
            yield cls(archive)

    @staticmethod
    def member_kind(member: tarfile.TarInfo) -> ArchiveMemberKind:
        if member.isdir():
            return "directory"
        if member.isfile():
            return "file"
        if member.issym():
            return "symlink"
        if member.islnk():
            return "hardlink"
        return "other"

    @classmethod
    def describe(cls, member: tarfile.TarInfo) -> ArchiveMember:
        return ArchiveMember(
            path=member.name,
            kind=cls.member_kind(member),
            mode=stat.S_IMODE(member.mode),
            link_target=member.linkname if member.issym() or member.islnk() else None,
            size=member.size,
        )

    def members(self) -> tuple[ArchiveMember, ...]:
        return tuple(self.describe(member) for member in self._archive.getmembers())

    def _extract_member(self, member: str, destination: Path) -> None:
        self._archive.extract(member, destination, filter="data")

    def extract_tree(
        self, entries: Sequence[InstalledMember], destination: Path
    ) -> None:
        members = []
        for entry in entries:
            member = copy.copy(self._archive.getmember(entry.member.path))
            member.name = entry.path
            members.append(member)
        # extractall restores directory attributes after extracting their children.
        self._archive.extractall(destination, members=members, filter="data")
