"""Convert a tar to an uncompressed tar with regular files in place of hardlinks.

Also invoked directly by chezmoi's archive filter using the host's python3.
"""

from __future__ import annotations

import os
import shutil
import sys
import tarfile
import tempfile
from typing import BinaryIO


def materialize_hardlinks(source: BinaryIO, output: BinaryIO) -> None:
    # Tar hardlinks refer to a preceding member by its archive-root name.
    # Store payload offsets on disk so that stdin and stdout can both be pipes.
    files: dict[str, tuple[int, int, int]] = {}
    with (
        tarfile.open(fileobj=source, mode="r|*") as archive,
        tarfile.open(fileobj=output, mode="w|") as result,
        tempfile.TemporaryFile() as payloads,
    ):
        for member in archive:
            if member.isreg():
                data = archive.extractfile(member)
                assert data is not None
                offset = payloads.seek(0, os.SEEK_END)
                shutil.copyfileobj(data, payloads)
                files[member.name] = offset, member.size, member.mode
            elif member.islnk():
                if member.linkname not in files:
                    raise tarfile.TarError(
                        f"invalid tar hardlink: {member.name} -> {member.linkname}"
                    )
                files[member.name] = files[member.linkname]
                offset, member.size, member.mode = files[member.name]
                member.type = tarfile.REGTYPE
                member.linkname = ""
                member.pax_headers = {
                    k: v
                    for k, v in member.pax_headers.items()
                    if k not in ("linkpath", "size")
                }
            else:
                result.addfile(member)
                continue
            payloads.seek(offset)
            result.addfile(member, payloads)


if __name__ == "__main__":
    materialize_hardlinks(sys.stdin.buffer, sys.stdout.buffer)
