# Machine configuration

During the first init, chezmoi prompts once for machine-local options and stores the answers in `~/.config/chezmoi/chezmoi.toml`:

- `shell.fish.auto`: default `true`. Enter fish automatically from fallback bash/zsh sessions.
- `toolchains.node`: default `true`; pnpm installs the latest Node.js LTS release.
- `toolchains.rustup`: default `none`; choose `minimal`, `default`, or `complete` to install rustup with that profile.
- `rime.enabled`: macOS-only, default `true`. Deploy Rime configuration and the rime-ice repository to `~/Library/Rime`; Squirrel must be installed and added as a macOS input source separately.
- `git.signingkeyFile`: choose a public key found in `~/.ssh/*.pub` by filename stem, such as `id_ed25519`, or choose `none` to leave signing off.
- `services.development`, `services.llm`, and `services.smb`: Linux-only service groups, all defaulting to `false`. Development manages dev-box, Codex, Kimi, DSH, marimo, secret-proxy, their builds, and the secret-proxy network; LLM manages Bifrost, vLLM, their builds, and the inference network; SMB manages the independent Samba service.
- `ingress.caddy` and `ingress.cloudflared`: Linux-only ingress groups, both defaulting to `false`. Caddy serves private HTTPS routes and Cloudflare Tunnel serves public routes. These questions appear only when `services.development` or `services.llm` is enabled; otherwise initialization writes both ingress flags as `false`, including previously saved choices.
- `device.tailscale_ipv4`: asked only when development, SMB, or Caddy is enabled, default empty; the address used for published SSH, HTTPS, or SMB ports. Empty leaves those services unpublished.
- `device.domain`: asked only when Caddy or Cloudflare Tunnel is enabled and required; the device's complete service DNS suffix, such as `workstation.example.com`.
- `acme.ca`: written only when Caddy is enabled; initialization sets the ZeroSSL production ACME URL without prompting.
- `acme.email`: asked only when Caddy is enabled and required for ZeroSSL. Stored only in machine-local configuration.
- `cloudflared.tunnel_id`: required when Cloudflare Tunnel is enabled; UUID of a locally managed Tunnel. Runtime credentials are stored in the standard user encrypted credential store and decrypted by systemd and mounted read-only into the container.
- `cloudflared.access_team`: required when Cloudflare Tunnel is enabled; the team-name prefix of `<team>.cloudflareaccess.com`.
- `cloudflared.access_aud`: required when Cloudflare Tunnel is enabled; the 64-character hexadecimal AUD of one Access application covering the enabled public browser hostnames. Keep the public LLM API hostname outside that application.

Use `--promptDefaults` to choose defaults non-interactively. Prefer `--override-data` when scripted bootstrap needs non-default answers.

## Updating configuration

Edit saved answers with `chezmoi edit-config`, then inspect `chezmoi diff` before applying. Run `chezmoi init --prompt` to revisit initialization prompts without applying changes.

Reinitialization emits all container and ingress settings only on Linux, and emits device or ACME settings only for the groups that need them. It resets `acme.ca` to ZeroSSL when Caddy is enabled, including configurations that previously selected another CA; supply a contact email when prompted.

For containers, follow the [apply and startup workflow](containers.md#apply-build-and-start). Disabling a group stops managing its files; it does not stop or remove deployed services.

Rime is also controlled per machine through its initialization prompt. Disabling `rime.enabled` stops managing both its configuration and rime-ice; it does not remove existing files or disable the input method. Redeploy from Squirrel's input menu after applying Rime changes.

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell and leave `shell.fish.auto = true`; interactive bash/zsh sessions will automatically enter fish when it is available. On machines where the login shell is already fish, set `shell.fish.auto = false`.

Auto-fish is only for fallback bash/zsh sessions. Fish sessions do not source it, and fish exports `_CHEZMOI_FISH_SESSION=1` so child bash/zsh shells stay in the shell that was explicitly started.

To start a shell without this automatic handoff:

```sh
bash --norc
zsh -f
```
