"""Open one format-specific archive behind a common resource interface."""

import tarfile
import zipfile
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from ..models import TAR_RE, ZIP_RE, PackageError
from .base import Archive
from .tar import TarArchive
from .zip import ZipArchive


@contextmanager
def open_archive(path: Path) -> Iterator[Archive]:
    try:
        if TAR_RE.search(path.name):
            opener = TarArchive.open
        elif ZIP_RE.search(path.name):
            opener = ZipArchive.open
        else:
            raise PackageError(f"unsupported archive extension: {path.name}")
        with opener(path) as archive:
            yield archive
    except (OSError, tarfile.TarError, zipfile.BadZipFile, UnicodeError) as error:
        raise PackageError(f"archive {path}: {error}") from error
