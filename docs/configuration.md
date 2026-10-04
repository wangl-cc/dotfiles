# Machine configuration

During the first init, chezmoi prompts once for machine-local options and stores the answers in `~/.config/chezmoi/chezmoi.toml`:

- `shell.fish.auto`: default `true`. Enter fish automatically from fallback bash/zsh sessions.
- `toolchains.node`: default `true`; pnpm installs the latest Node.js LTS release.
- `toolchains.rustup`: default `none`; choose `minimal`, `default`, or `complete` to install rustup with that profile.
- `rime.enabled`: macOS-only, default `true`. Deploy Rime configuration and the rime-ice repository to `~/Library/Rime`; Squirrel must be installed and added as a macOS input source separately.
- `git.signingkey`: enter a complete SSH public key or a public key file path beginning with `/` or `~/`, such as `~/.ssh/id_ed25519.pub`; leave empty to disable signing. Initialization validates the public key with `ssh-keygen` and saves its value with a `key::` prefix. Signing requires the matching private key in an accessible SSH agent.
- `services.development` and `services.smb`: Linux-only service groups, both defaulting to `false`. Development manages dev-box, claude-box, Codex, Kimi, DSH, marimo, secret-proxy, their builds, and the secret-proxy network; SMB manages the independent Samba service.
- `ingress.caddy` and `ingress.cloudflared`: Linux-only ingress groups, both defaulting to `false`. Caddy serves private HTTPS routes and Cloudflare Tunnel serves public routes. These questions appear only when `services.development` is enabled; otherwise initialization writes both ingress flags as `false`, including previously saved choices.
- `device.tailscale_ipv4`: asked only when development, SMB, or Caddy is enabled, default empty; the address used for published SSH, HTTPS, or SMB ports. Empty leaves those services unpublished.
- `device.domain`: asked only when Caddy or Cloudflare Tunnel is enabled and required; the device's complete service DNS suffix, such as `workstation.example.com`.
- `acme.ca`: written only when Caddy is enabled; initialization sets the ZeroSSL production ACME URL without prompting.
- `acme.email`: asked only when Caddy is enabled and required for ZeroSSL. Stored only in machine-local configuration.
- `cloudflared.tunnel_id`: required when Cloudflare Tunnel is enabled; UUID of a locally managed Tunnel. Runtime credentials are stored in the standard user encrypted credential store and decrypted by systemd and mounted read-only into the container.
- `cloudflared.access_team`: required when Cloudflare Tunnel is enabled; the team-name prefix of `<team>.cloudflareaccess.com`.
- `cloudflared.access_aud`: required when Cloudflare Tunnel is enabled; the 64-character hexadecimal AUD of one Access application covering the enabled public browser hostnames.

Use `--promptDefaults` to choose defaults non-interactively. Use flags such as `--promptString` and `--promptBool` when scripted bootstrap needs non-default answers.

## Updating configuration

Edit saved answers with `chezmoi edit-config`, then inspect `chezmoi diff` before applying. Run `chezmoi init --prompt` to revisit initialization prompts without applying changes.

Reinitialization emits all container and ingress settings only on Linux, and emits device or ACME settings only for the groups that need them. It resets `acme.ca` to ZeroSSL when Caddy is enabled, including configurations that previously selected another CA; supply a contact email when prompted.

For containers, follow the [apply and startup workflow](containers.md#apply-build-and-start). Disabling a group stops managing its files; it does not stop or remove deployed services.

Rime is also controlled per machine through its initialization prompt. Disabling `rime.enabled` stops managing both its configuration and rime-ice; it does not remove existing files or disable the input method. Redeploy from Squirrel's input menu after applying Rime changes.

### Retiring local inference

The `services.llm` option and the vLLM/Bifrost deployment have been removed. Run `chezmoi init` to regenerate machine-local configuration without the old `services.llm` key. Use `--prompt` if other saved choices need to change. Ingress now requires `services.development`; reinitialization writes both ingress flags as `false` when development is disabled.

Existing installations require explicit cleanup because removing sources does not remove previously deployed files or services:

1. Move translation clients to their provider's API, then stop `vllm.service` and `bifrost.service`. Stop shared Caddy/cloudflared services before changing their networks; this briefly interrupts development HTTPS access.
2. Remove the retired targets from `~/.config/containers/systemd`: `vllm.container`, `vllm.build`, `bifrost.container`, `llm.network`, and `inference.network`, plus `~/.config/bifrost`. Inspect `chezmoi diff` and apply the updated Caddy/cloudflared targets. If development is disabled, remove their obsolete targets instead.
3. Run `systemctl --user daemon-reload`, then restart the retained ingress services. Check their development routes and remove the unused `llm` and `inference` Podman networks after their containers have detached.
4. Remove obsolete inference images and model/compiler caches once no other consumer needs them. Decide whether to archive or delete the `bifrost-data` volume and its `bifrost.env` encrypted credential together; they contain historical configuration and usage records.

DNS routes and Cloudflare Access applications are managed externally. Remove the retired `llm.<device.domain>`, `llm-<device.domain>`, and `admin-llm-<device.domain>` hostnames from those resources while retaining development routes. This retirement does not add automatic deletion rules for other machines.

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell and leave `shell.fish.auto = true`; interactive bash/zsh sessions will automatically enter fish when it is available. On machines where the login shell is already fish, set `shell.fish.auto = false`.

Auto-fish is only for fallback bash/zsh sessions. Fish sessions do not source it, and fish exports `_CHEZMOI_FISH_SESSION=1` so child bash/zsh shells stay in the shell that was explicitly started.

To start a shell without this automatic handoff:

```sh
bash --norc
zsh -f
```
