#!/usr/bin/env python3
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
from pathlib import Path
from urllib.parse import unquote, urlparse


DEFAULT_BASE_DIR = "/tmp/external-repo-research"


class CheckoutError(RuntimeError):
    """Raised when the checkout cannot be prepared safely."""


def run_git(args: list[str], cwd: Path | None = None) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd else None,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        command = shlex.join(["git", *args])
        stderr = result.stderr.strip()
        detail = f": {stderr}" if stderr else ""
        raise CheckoutError(f"{command} failed{detail}")
    return result.stdout.strip()


def sanitize_segment(value: str) -> str:
    value = value.strip()
    if value.endswith(".git"):
        value = value[:-4]
    value = re.sub(r"[^A-Za-z0-9._-]+", "-", value).strip(".-")
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


def remote_destination(repo_url: str, base_dir: Path) -> Path:
    scp_like = re.match(r"^(?:[^@/:]+@)?([^/:]+):(.+)$", repo_url)
    if (
        scp_like
        and "://" not in repo_url
        and not repo_url.startswith(("/", "./", "../", "~"))
    ):
        host = scp_like.group(1)
        path = scp_like.group(2)
        segments = [host, *path.split("/")]
    else:
        parsed = urlparse(repo_url)
        if parsed.scheme == "file":
            return local_destination(repo_url, base_dir, parsed.path)
        if parsed.scheme not in {"git", "http", "https", "ssh"}:
            raise CheckoutError(
                "repository URL must be a git/http/https/ssh/file URL, "
                "an scp-like git URL, or a local path"
            )
        if not parsed.hostname:
            raise CheckoutError("repository URL is missing a host")
        segments = [parsed.hostname, *unquote(parsed.path).split("/")]

    safe_segments = [sanitize_segment(segment) for segment in segments if segment]
    if len(safe_segments) < 2:
        raise CheckoutError("repository URL is missing an owner or repository path")
    return base_dir.joinpath(*safe_segments)


def destination_for(repo_url: str, base_dir: Path) -> Path:
    parsed = urlparse(repo_url)
    path_candidate = Path(repo_url).expanduser()
    looks_local = (
        parsed.scheme == ""
        and (repo_url.startswith(("/", "./", "../", "~")) or path_candidate.exists())
    )
    if looks_local:
        return local_destination(repo_url, base_dir)
    return remote_destination(repo_url, base_dir)


def is_git_checkout(path: Path) -> bool:
    if not path.exists():
        return False
    try:
        run_git(["rev-parse", "--is-inside-work-tree"], cwd=path)
    except CheckoutError:
        return False
    return True


def ensure_clean(path: Path) -> None:
    status = run_git(["status", "--porcelain"], cwd=path)
    if status:
        raise CheckoutError(
            f"{path} has local changes; use a clean checkout or a different base dir"
        )


def checkout_ref(path: Path, ref: str) -> None:
    run_git(["fetch", "--depth", "1", "origin", ref], cwd=path)
    run_git(["checkout", "--detach", "FETCH_HEAD"], cwd=path)


def prepare_checkout(
    repo_url: str,
    base_dir: Path,
    ref: str | None,
) -> dict[str, object]:
    destination = destination_for(repo_url, base_dir)
    cloned = False
    reused = False

    if destination.exists():
        if not is_git_checkout(destination):
            raise CheckoutError(f"{destination} exists but is not a git checkout")
        ensure_clean(destination)
        reused = True
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        try:
            clone_args = ["clone", "--depth", "1"]
            if ref:
                clone_args.append("--no-checkout")
            run_git([*clone_args, "--", repo_url, str(destination)])
            cloned = True
        except CheckoutError:
            if destination.exists():
                shutil.rmtree(destination)
            raise

    try:
        if ref:
            checkout_ref(destination, ref)
    except CheckoutError:
        if cloned and destination.exists():
            shutil.rmtree(destination)
        raise

    commit = run_git(["rev-parse", "HEAD"], cwd=destination)
    origin_url = run_git(["config", "--get", "remote.origin.url"], cwd=destination)

    return {
        "url": repo_url,
        "origin_url": origin_url,
        "path": str(destination),
        "commit": commit,
        "ref": ref,
        "cloned": cloned,
        "reused": reused,
    }


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
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
