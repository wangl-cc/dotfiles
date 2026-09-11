# Machine configuration

During the first init, chezmoi prompts once for machine-local options and stores the answers in `~/.config/chezmoi/chezmoi.toml`:

- `shell.fish.auto`: default `true`. Enter fish automatically from fallback bash/zsh sessions.
- `toolchains.node`: default `true`; pnpm installs the latest Node.js LTS release.
- `toolchains.rustup`: default `none`; choose `minimal`, `default`, or `complete` to install rustup with that profile.
- `git.signingkeyFile`: choose a public key found in `~/.ssh/*.pub` by filename stem, such as `id_ed25519`, or choose `none` to leave signing off.
- `device.tailscale_ipv4`: default empty; shared device address used to publish workspace and SMB ports on Tailscale. Empty leaves workspace localhost-only and SMB unpublished.
- `device.domain`: default empty; the device's complete service DNS suffix, such as `workstation.example.com`. Required when workspace is enabled.
- `workspace.enabled`: default `false`; manage the workspace Pod, its five members, and their build configurations.
- `smb.enabled`: default `false`; independently manage the SMB container and build configuration.
- `acme.ca`: defaults to the ZeroSSL production ACME URL; Let's Encrypt is also available.
- `acme.email`: defaults to empty; required when workspace uses ZeroSSL. Stored only in machine-local configuration.

Use `--promptDefaults` to choose defaults non-interactively. Prefer `--override-data` when scripted bootstrap needs non-default answers.

## Updating configuration

Edit saved answers with `chezmoi edit-config`, then inspect `chezmoi diff` before applying. Run `chezmoi init --prompt` to revisit initialization prompts without applying changes.

## Container configuration migration

Existing workspace installations must add `acme.ca` and `acme.email` with `chezmoi edit-config`, or run `chezmoi init` and answer the new prompts before applying Caddyfile. See the [container guide](dev-containers.md) for the local configuration example. Keep the existing Caddy data volume to preserve accounts and certificates.

For existing installations, use `chezmoi edit-config` to move the former `tailscale.ipv4` to `device.tailscale_ipv4` and `dev_pod.domain` to `device.domain`, then explicitly set `workspace.enabled` and `smb.enabled`. Alternatively, run `chezmoi init --prompt` without applying and supply the new answers. Remove the obsolete `[data.tailscale]` and `[data.dev_pod]` tables after migration. Hostname no longer controls deployment. Missing enable flags are treated as disabled; ignoring files does not stop or remove existing services. See the [container guide](dev-containers.md) before applying the Pod rename.

DSH now trusts only hosts supplied through its CLI. Its existing `~/.dsh/.env` is left untouched to preserve user-added settings; the former Tailnet environment entry is no longer used.

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell and leave `shell.fish.auto = true`; interactive bash/zsh sessions will automatically enter fish when it is available. On machines where the login shell is already fish, set `shell.fish.auto = false`.

Auto-fish is only for fallback bash/zsh sessions. Fish sessions do not source it, and fish exports `_CHEZMOI_FISH_SESSION=1` so child bash/zsh shells stay in the shell that was explicitly started.

To start a shell without this automatic handoff:

```sh
bash --norc
zsh -f
```
