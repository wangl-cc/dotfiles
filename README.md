# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/), with configuration, portable CLI packages, and optional containers.

## Bootstrap

Install chezmoi into the user directory and apply this repository:

```sh
curl -fsLS https://get.chezmoi.io | sh -s -- \
  -b "$HOME/.local/bin" \
  init --apply https://github.com/wangl-cc/dotfiles.git
```

Initialization prompts for machine-local options and saves them in `~/.config/chezmoi/chezmoi.toml`.

## Documentation

- [Machine configuration](docs/configuration.md): initialization options and shell behavior.
- [Portable packages](docs/portable-packages.md): package strategy and manifest helper.
- [Container services](docs/containers.md): services, networks, credentials, and deployment.
