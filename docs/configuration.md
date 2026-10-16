# Machine configuration

During the first init, chezmoi prompts once for machine-local options and stores the answers in `~/.config/chezmoi/chezmoi.toml`:

- `machine.profile`: default `default`. `cloud` is for ephemeral cloud containers such as Claude Code cloud sessions: it installs only the portable packages listed in `home/.chezmoidata/profiles.toml` and leaves the container's own `.bashrc`, `.bash_profile`, `.zshenv`, and `~/.cargo/config.toml` alone. pnpm is not installed there, so pair it with `toolchains.node = false`. Configurations created before this option behave as `default` until the next `chezmoi init`.
- `shell.fish.auto`: default `true`. Enter fish automatically from fallback bash/zsh sessions.
- `toolchains.node`: default `true`; pnpm installs the latest Node.js LTS release.
- `toolchains.rustup`: default `none`; choose `minimal`, `default`, or `complete` to install rustup with that profile.
- `rime.enabled`: macOS-only, default `true`. Deploy Rime configuration and the rime-ice repository to `~/Library/Rime`; Squirrel must be installed and added as a macOS input source separately.
- `git.signingkey`: enter a complete SSH public key or a public key file path beginning with `/` or `~/`, such as `~/.ssh/id_ed25519.pub`; leave empty to disable signing. Initialization validates the public key with `ssh-keygen` and saves its value with a `key::` prefix. Signing requires the matching private key in an accessible SSH agent.
- `services.development` and `services.smb`: Linux-only service groups, both defaulting to `false`. Development manages dev-box, Claude, Codex, Kimi, DSH, marimo, secret-proxy, their builds, and the secret-proxy network; SMB manages the independent Samba service.
- `ingress.caddy`: Linux-only private HTTPS ingress through Tailscale, default `false`. This question appears only when `services.development` is enabled; otherwise initialization writes `false`, including previously saved choices.
- `device.tailscale_ipv4`: asked only when development or SMB is enabled, default empty; the address used for published SSH, HTTPS, or SMB ports. Empty leaves those services unpublished.
- `device.domain`: asked only when Caddy is enabled and required; the device's complete service DNS suffix, such as `workstation.example.com`.
- `acme.ca`: written only when Caddy is enabled; initialization sets the ZeroSSL production ACME URL without prompting.
- `acme.email`: asked only when Caddy is enabled and required for ZeroSSL. Stored only in machine-local configuration.

Use `--promptDefaults` to choose defaults non-interactively. Use flags such as `--promptString` and `--promptBool` when scripted bootstrap needs non-default answers.

## Updating configuration

Edit saved answers with `chezmoi edit-config`, then inspect `chezmoi diff` before applying. Run `chezmoi init --prompt` to revisit initialization prompts without applying changes.

Reinitialization emits all container and ingress settings only on Linux, and emits device or ACME settings only for the groups that need them. It resets `acme.ca` to ZeroSSL when Caddy is enabled, including configurations that previously selected another CA; supply a contact email when prompted.

For containers, follow the [apply and startup workflow](containers.md#apply-build-and-start). Disabling a group stops managing its files; it does not stop or remove deployed services.

Rime is also controlled per machine through its initialization prompt. Disabling `rime.enabled` stops managing both its configuration and rime-ice; it does not remove existing files or disable the input method. Redeploy from Squirrel's input menu after applying Rime changes.

### Retiring local inference

The `services.llm` option and the vLLM/Bifrost deployment have been removed. Run `chezmoi init` to regenerate machine-local configuration without the old `services.llm` key. Use `--prompt` if other saved choices need to change. Ingress now requires `services.development`; reinitialization writes `ingress.caddy = false` when development is disabled.

Existing installations require explicit cleanup because removing sources does not remove previously deployed files or services:

1. Move translation clients to their provider's API, then stop `vllm.service` and `bifrost.service`. Stop Caddy before changing its networks; this briefly interrupts development HTTPS access. Retire any deployed cloudflared service using the steps below.
2. Remove the retired targets from `~/.config/containers/systemd`: `vllm.container`, `vllm.build`, `bifrost.container`, `llm.network`, and `inference.network`, plus `~/.config/bifrost`. Inspect `chezmoi diff` and apply the updated Caddy targets. If development is disabled, remove its obsolete targets instead.
3. Run `systemctl --user daemon-reload`, then restart the retained ingress services. Check their development routes and remove the unused `llm` and `inference` Podman networks after their containers have detached.
4. Remove obsolete inference images and model/compiler caches once no other consumer needs them. Decide whether to archive or delete the `bifrost-data` volume and its `bifrost.env` encrypted credential together; they contain historical configuration and usage records.

DNS routes and Cloudflare Access applications are managed externally. Remove the retired `llm.<device.domain>`, `llm-<device.domain>`, and `admin-llm-<device.domain>` hostnames from those resources while retaining development routes. This retirement does not add automatic deletion rules for other machines.

### Retiring public ingress

Kimi, DSH, and marimo use private HTTPS through Tailscale and Caddy. The cloudflared deployment, `ingress.cloudflared`, and `cloudflared` settings have been removed. Tailscale SSH and SMB, and HTTP between workspace containers, remain available. Cloudflare remains the DNS provider for private names and Caddy's certificate challenges.

Run `chezmoi init` to remove the retired keys from machine-local configuration. The default remains `ingress.caddy = false`; a saved Caddy choice is retained only when development is enabled. If Caddy was previously retired on the machine, enable `services.development` and `ingress.caddy` with `chezmoi init --prompt`, and supply the Tailscale address, DNS suffix, and ACME email. Plain reinitialization does not automatically enable Caddy for an installation that only used the Tunnel. A saved or overridden Tunnel choice no longer enables ingress or requests Tunnel credentials. Tailscale address prompts remain for development and SMB.

For existing deployments:

1. Prepare Caddy's `cloudflare-dns-token` encrypted credential and DNS-only records pointing to the Tailscale address. Restore archived `caddy-data` and `caddy-config` volumes if available, or let Caddy provision new certificates. Preserve those DNS records and the DNS API token when removing Tunnel resources.
2. Inspect the full `chezmoi diff`, then apply Caddy's configuration and Quadlets plus the updated Kimi environment and DSH web hosts configuration. Run `systemctl --user daemon-reload`, start Caddy, and restart Kimi and DSH to load private host allowlists; this interrupts their sessions. marimo does not need a restart for this ingress change.
3. Verify `kimi.<device.domain>`, `dsh.<device.domain>`, and `marimo.<device.domain>` from a Tailscale client, including the applicable Tailscale access rules. Stop `cloudflared.service`, then remove `~/.config/cloudflared` and `~/.config/containers/systemd/cloudflared.container`, and run `systemctl --user daemon-reload` again.
4. Archive any needed Tunnel configuration and encrypted credential before removing `~/.config/credstore.encrypted/cloudflared-credentials` and unused cloudflared images. Remove dedicated public DNS routes such as `kimi-<device.domain>`, `dsh-<device.domain>`, and `marimo-<device.domain>`. Delete the Tunnel and Access application only after checking that no other route uses them; these resources are managed externally and require their own permissions.

No automatic removal rules are added for other machines. Removing the connector and public DNS does not itself delete the Tunnel or Access application in Cloudflare.

## Fish

`fish` is the primary interactive shell. On systems where changing the login shell is not allowed, keep the system login shell and leave `shell.fish.auto = true`; interactive bash/zsh sessions will automatically enter fish when it is available. On machines where the login shell is already fish, set `shell.fish.auto = false`.

Auto-fish is only for fallback bash/zsh sessions. Fish sessions do not source it, and fish exports `_CHEZMOI_FISH_SESSION=1` so child bash/zsh shells stay in the shell that was explicitly started.

To start a shell without this automatic handoff:

```sh
bash --norc
zsh -f
```
