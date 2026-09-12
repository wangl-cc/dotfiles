# Portable packages helper

This uv project maintains the parent chezmoi repository's pinned GitHub release packages. It is used by agents and CI, with no global installation. Package configuration and installation templates remain under the repository's `home/` directory; see the [package guide](../docs/portable-packages.md) for usage and [agent skill](../.agents/skills/portable-pkgs/SKILL.md) for argument syntax.

Run from the repository root:

```sh
uv run --locked --project portable-pkgs portable-pkgs list
uv run --locked --project portable-pkgs portable-pkgs inspect sharkdp/fd
uv run --locked --project portable-pkgs portable-pkgs update --verify
```

From this project directory, omit `--project portable-pkgs`. From elsewhere, pass the absolute project path. uv installs the project into its local environment and exposes the console entry declared in `pyproject.toml`. Dependencies and development tools are pinned in `uv.lock`.

The default manifest is `home/.chezmoidata/portable-pkgs.yaml` in the checkout containing `src/portable_pkgs/`, independent of the current directory. `PORTABLE_PKGS_MANIFEST` overrides it; relative overrides are relative to the current directory. This tool is intended to run from a checkout through uv, rather than as a separately distributed application.

## Structure

- `src/portable_pkgs/cli.py` defines CLI commands using Pydantic Settings.
- `requests.py` owns the immutable add input schema and pure configuration inheritance; `operations.py` owns release I/O and resolution.
- `models.py` defines immutable package specifications; `github.py` owns API (githubkit) and download (httpx) boundaries.
- `archives/` provides tar/ZIP resource adapters; `installation.py` applies shared installation policy.
- `storage.py` and `sources.py` coordinate manifest persistence and generated chezmoi sources.
- `tests/` contains ordinary unittest modules, including isolated chezmoi package installation tests.

## Validation

From the repository root:

```sh
uv run --locked --project portable-pkgs python -m unittest discover -s portable-pkgs/tests
uv run --locked --project portable-pkgs ty check portable-pkgs
uv run --locked --project portable-pkgs ruff check portable-pkgs
uv run --locked --project portable-pkgs ruff format --check portable-pkgs
```

Append `-k <test-name>` to select tests. Integration tests need `chezmoi` on PATH and permission to use a localhost HTTP server and isolated temporary files. Tests do not apply packages to the real home directory. No custom test runner or module search-path configuration is required. `[tool.ruff]` in `pyproject.toml` selects the enforced lint rules and `ruff format` owns layout; the scheduled bump workflow only updates packages, so run all four commands locally before committing.

## Retired global entry

The former `~/.local/bin/portable-pkgs` script is no longer distributed by this repository. Installed package bundles under `~/.local/share/portable-pkgs/` remain part of the managed package configuration.
