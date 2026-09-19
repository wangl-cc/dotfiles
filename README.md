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

Container deployment prompts appear only on Linux, and networking and ACME prompts follow the enabled services. Run `chezmoi init --prompt` without applying to regenerate existing configuration with these conditions; enabled workspaces initialize `acme.ca` to ZeroSSL and require a contact email.

## Updates

```sh
chezmoi update
```

Use `chezmoi edit-config` to change local options, then review `chezmoi diff` before `chezmoi apply`. When initialization options change, run `chezmoi init --prompt` without applying first; see the [configuration and migration notes](docs/configuration.md).

## Documentation

- [Machine configuration](docs/configuration.md): initialization options, migration, and shell behavior.
- [Portable packages](docs/portable-packages.md): package strategy and manifest helper.
- [Development containers](docs/dev-containers.md): workspace Pod, HTTPS, and maintenance.
- [Secret proxy](containers/secret-proxy/README.md): HTTP authentication and encrypted host credentials.
- [Samba container](containers/smb-box/README.md): file sharing.
