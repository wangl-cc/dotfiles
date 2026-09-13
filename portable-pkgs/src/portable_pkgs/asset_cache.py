"""Checksum-addressed cache; callers always consume a verified private copy."""

import hashlib
import os
import shutil
import tempfile
from pathlib import Path

from pydantic import TypeAdapter

from .models import SHA256, DownloadedAsset


class AssetCache:
    def __init__(self, directory: Path) -> None:
        self.directory = directory

    def restore(self, sha256: str, destination: Path) -> DownloadedAsset | None:
        sha256 = TypeAdapter(SHA256).validate_python(sha256)
        cached = self.directory / sha256
        try:
            with cached.open("rb") as source, destination.open("wb") as output:
                shutil.copyfileobj(source, output)
        except FileNotFoundError:
            return None
        with destination.open("rb") as source:
            actual = hashlib.file_digest(source, "sha256").hexdigest()
        if actual != sha256:
            cached.unlink(missing_ok=True)
            destination.unlink()
            return None
        return DownloadedAsset(path=destination, sha256=actual)

    def store(self, asset: DownloadedAsset) -> None:
        self.directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        cached = self.directory / asset.sha256
        if cached.exists():
            return
        with tempfile.TemporaryDirectory(
            dir=self.directory, prefix=".pending-"
        ) as pending:
            stage = Path(pending) / "asset"
            stage.touch(mode=0o600)
            with asset.path.open("rb") as source, stage.open("wb") as output:
                shutil.copyfileobj(source, output)
            # Rename only complete, verified assets; abandoned staging names are
            # never eligible for reuse. Concurrent writers publish the same hash.
            os.replace(stage, cached)
