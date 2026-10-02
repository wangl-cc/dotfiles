# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/), with shell and tool configuration, portable CLI packages, and optional containers.

## Bootstrap

Install chezmoi into the user directory and apply this repository:

```sh
curl -fsLS https://get.chezmoi.io | sh -s -- \
  -b "$HOME/.local/bin" \
  init --apply https://github.com/wangl-cc/dotfiles.git
```

Initialization prompts for machine-local options and saves them in `~/.config/chezmoi/chezmoi.toml`.

Initialization also prepends `~/.local/bin` and `~/.cargo/bin` to the saved PATH for chezmoi and its child processes. The remaining PATH entries are captured at initialization; use `chezmoi edit-config` to update the saved `env.PATH` if those search paths change.

Containers are Linux-only and optional. See [machine configuration](docs/configuration.md) for service choices and the [container guide](docs/containers.md) for credentials, DNS, and startup.

## Updates

```sh
chezmoi update
```

Use `chezmoi edit-config` to change local options, or `chezmoi init --prompt` to revisit initialization choices; see [machine configuration](docs/configuration.md).

On existing Macs, run `chezmoi init` once to add the `rime.enabled` option before diffing or applying this update. Rime configuration and rime-ice are now available on every Mac through this prompt (default `true`), replacing the old hostname restriction. After reviewing `chezmoi diff`, use `chezmoi apply ~/Library/Rime` to apply only Rime, then redeploy from Squirrel's input menu.

Local inference and Bifrost have been retired. Run `chezmoi init` to remove the old `services.llm` bootstrap setting; ingress now requires development services. Previously deployed services need explicit shutdown and target cleanup before reloading systemd and restarting retained ingress. Follow the [migration steps](docs/configuration.md#retiring-local-inference); DNS and Cloudflare Access resources are managed separately.

For local edits, use `chezmoi diff` followed by `chezmoi apply`. Review scripts and external-package changes as part of the diff. Container service reloads and restarts are separate from applying dotfiles.

## Documentation

- [Machine configuration](docs/configuration.md): initialization options and shell behavior.
- [Portable packages](docs/portable-packages.md): package strategy and manifest helper.
- [Container services](docs/containers.md): services, networks, credentials, and deployment.
