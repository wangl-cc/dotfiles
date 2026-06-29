#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Prepare a temporary read-only checkout for external repository research."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from urllib.parse import unquote, urlparse


DEFAULT_BASE_DIR = "/tmp/external-repo-research"
ALLOWED_REMOTE_SCHEMES = frozenset({"git", "http", "https", "ssh"})
LOCAL_PREFIXES = ("/", "./", "../", "~")
SAFE_SEGMENT_RE = re.compile(r"[^A-Za-z0-9._-]+")
SCP_LIKE_URL_RE = re.compile(r"^(?:[^@/:]+@)?([^/:]+):(.+)$")


class CheckoutError(RuntimeError):
    """Raised when the checkout cannot be prepared safely."""


@dataclass(frozen=True)
class CheckoutResult:
    url: str
    origin_url: str
    path: str
    commit: str
    ref: str | None
    cloned: bool
    reused: bool


class Git:
    def __init__(self, executable: str = "git") -> None:
        self.executable = executable

    def run(self, args: list[str], cwd: Path | None = None) -> str:
        command = [self.executable, *args]
        result = subprocess.run(
            command,
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        if result.returncode != 0:
            stderr = result.stderr.strip()
            detail = f": {stderr}" if stderr else ""
            raise CheckoutError(f"{shlex.join(command)} failed{detail}")
        return result.stdout.strip()


def sanitize_segment(value: str) -> str:
    value = value.strip()
    if value.endswith(".git"):
        value = value[:-4]
    value = SAFE_SEGMENT_RE.sub("-", value).strip(".-")
    if not value or value in {".", ".."}:
        raise CheckoutError("repository URL does not contain a safe path segment")
    return value


def local_destination(
    repo_url: str,
    base_dir: Path,
    parsed_path: str | None = None,
) -> Path:
    raw_path = parsed_path if parsed_path is not None else repo_url
    path = Path(unquote(raw_path)).expanduser()
    stable_key = str(path.resolve()) if path.exists() else str(path.absolute())
    digest = hashlib.sha256(stable_key.encode("utf-8")).hexdigest()[:12]
    name = sanitize_segment(path.name or "repo")
    return base_dir / "local" / f"{name}-{digest}"


def is_local_path(repo_url: str) -> bool:
    parsed = urlparse(repo_url)
    path = Path(repo_url).expanduser()
    return parsed.scheme == "" and (
        repo_url.startswith(LOCAL_PREFIXES) or path.exists()
    )


def scp_like_segments(repo_url: str) -> list[str] | None:
    match = SCP_LIKE_URL_RE.match(repo_url)
    if not match or "://" in repo_url or repo_url.startswith(LOCAL_PREFIXES):
        return None
    return [match.group(1), *match.group(2).split("/")]


def url_segments(repo_url: str, base_dir: Path) -> list[str] | Path:
    parsed = urlparse(repo_url)
    if parsed.scheme == "file":
        return local_destination(repo_url, base_dir, parsed.path)
    if parsed.scheme not in ALLOWED_REMOTE_SCHEMES:
        raise CheckoutError(
            "repository URL must be a git/http/https/ssh/file URL, "
            "an scp-like git URL, or a local path"
        )
    if not parsed.hostname:
        raise CheckoutError("repository URL is missing a host")
    return [parsed.hostname, *unquote(parsed.path).split("/")]


def remote_destination(repo_url: str, base_dir: Path) -> Path:
    segments = scp_like_segments(repo_url) or url_segments(repo_url, base_dir)
    if isinstance(segments, Path):
        return segments

    safe_segments = [sanitize_segment(segment) for segment in segments if segment]
    if len(safe_segments) < 2:
        raise CheckoutError("repository URL is missing an owner or repository path")
    return base_dir.joinpath(*safe_segments)


def destination_for(repo_url: str, base_dir: Path) -> Path:
    if is_local_path(repo_url):
        return local_destination(repo_url, base_dir)
    return remote_destination(repo_url, base_dir)


def is_git_checkout(path: Path, git: Git) -> bool:
    if not path.exists():
        return False
    try:
        git.run(["rev-parse", "--is-inside-work-tree"], cwd=path)
    except CheckoutError:
        return False
    return True


def ensure_clean(path: Path, git: Git) -> None:
    status = git.run(["status", "--porcelain"], cwd=path)
    if status:
        raise CheckoutError(
            f"{path} has local changes; use a clean checkout or a different base dir"
        )


def clone_checkout(repo_url: str, destination: Path, ref: str | None, git: Git) -> None:
    clone_args = ["clone", "--depth", "1"]
    if ref:
        clone_args.append("--no-checkout")
    git.run([*clone_args, "--", repo_url, str(destination)])


def checkout_ref(path: Path, ref: str, git: Git) -> None:
    git.run(["fetch", "--depth", "1", "origin", ref], cwd=path)
    git.run(["checkout", "--detach", "FETCH_HEAD"], cwd=path)


def prepare_checkout(
    repo_url: str,
    base_dir: Path,
    ref: str | None,
    git: Git | None = None,
) -> CheckoutResult:
    git = git or Git()
    destination = destination_for(repo_url, base_dir)
    cloned = False
    reused = False

    if destination.exists():
        if not is_git_checkout(destination, git):
            raise CheckoutError(f"{destination} exists but is not a git checkout")
        ensure_clean(destination, git)
        reused = True
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        try:
            clone_checkout(repo_url, destination, ref, git)
            cloned = True
        except CheckoutError:
            if destination.exists():
                shutil.rmtree(destination)
            raise

    try:
        if ref:
            checkout_ref(destination, ref, git)
    except CheckoutError:
        if cloned and destination.exists():
            shutil.rmtree(destination)
        raise

    return CheckoutResult(
        url=repo_url,
        origin_url=git.run(["config", "--get", "remote.origin.url"], cwd=destination),
        path=str(destination),
        commit=git.run(["rev-parse", "HEAD"], cwd=destination),
        ref=ref,
        cloned=cloned,
        reused=reused,
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prepare a temporary external repository checkout for research."
    )
    parser.add_argument("repo_url", help="Repository URL or local path to clone")
    parser.add_argument(
        "--ref",
        help="Branch, tag, pull-request ref, or commit-ish to fetch and check out",
    )
    parser.add_argument(
        "--base-dir",
        default=DEFAULT_BASE_DIR,
        help=f"Temporary checkout root (default: {DEFAULT_BASE_DIR})",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    base_dir = Path(args.base_dir).expanduser().resolve()
    try:
        result = prepare_checkout(args.repo_url, base_dir, args.ref)
    except CheckoutError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(json.dumps(asdict(result), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
