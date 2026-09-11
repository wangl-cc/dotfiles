# Development containers

The development Pod groups `dev-box`, `codex`, `kimi`, `dsh`, and `caddy` on one private network. dev-box provides SSH and the interactive compute environment; the agents run from installations in the shared home. Caddy exposes Kimi and DSH at `https://kimi.workstation.example.com` and `https://dsh.workstation.example.com`. SMB remains independent.

## Setup and migration

Run lifecycle commands on the host, not inside a development container. Migration recreates the existing containers and interrupts their sessions: use host SSH or a host terminal. Existing home and named-volume data are reused, but changes made only in a container's writable layer are lost.

### Host prerequisites

Use Podman 5.8 or later. Set `device.tailscale_ipv4` in local chezmoi data to the address reported by `tailscale ip -4`; if omitted, the Pod publishes only on localhost. Set the complete `device.domain` suffix in this machine's local `~/.config/chezmoi/chezmoi.toml`, not in repository data. All domain names below are examples:

```toml
[data.device]
tailscale_ipv4 = "100.64.0.1"
domain = "workstation.example.com"

[data.workspace]
enabled = true

[data.smb]
enabled = false

[data.acme]
ca = "https://acme.zerossl.com/v2/DV90"
email = "admin@example.com"
```

Both deployment switches default to false. The container directory's ignore rules independently select the complete workspace group and SMB, without hostname checks; Caddyfile follows the workspace switch. Enabling workspace requires a nonempty device domain at initialization. When a Tailscale IPv4 address is configured, the workspace Pod waits for Tailscale and verifies that exact address before binding its published ports. Disabling a group stops managing its files but does not remove or stop previously deployed services. Different devices may use different domains.

The Pod publishes TCP 2222 for SSH, TCP 443 for Caddy, and TCP 2718–2720 for marimo on localhost and the configured Tailscale IPv4 only. Check for port conflicts and wait for Tailscale to have its address before startup:

```sh
tailscale ip -4
ss -ltn
sysctl net.ipv4.ip_unprivileged_port_start
```

Rootless Podman needs `net.ipv4.ip_unprivileged_port_start` at most 443. If it is higher, an administrator must deliberately permit low-port binding before deployment. For example, `sudo sysctl -w net.ipv4.ip_unprivileged_port_start=443` changes it until reboot; persistence belongs in host `/etc/sysctl.d/`. This permits all unprivileged host users to bind available ports 443–1023, not just this Pod. The repository does not apply this host-wide change automatically.

### Cloudflare DNS and credentials

Create a Cloudflare API Token scoped to `example.com` with `Zone:Read` and `DNS:Edit`. Keep the raw token in a mode-0600 file outside the repository, preferably temporarily in the host runtime directory. Do not put it in the Caddyfile, shell history, or a committed environment file. Replace `/path/to/token` below with that file.

In the Cloudflare `example.com` zone, manually create a DNS-only wildcard A record named `*.workstation` pointing to the host Tailscale IPv4, or separate A records named `kimi.workstation` and `dsh.workstation`. These names correspond to `kimi.<device.domain>` and `dsh.<device.domain>`; adjust them together if changing the suffix. Do not enable Cloudflare's HTTP proxy.

Provide the token to Caddy through a host Podman secret:

```sh
podman secret create cloudflare-dns-token /path/to/token
```

Caddy manages ACME challenge TXT records and certificate renewal through the Cloudflare provider, not the A records. ZeroSSL is the default ACME issuer; Caddy uses the machine-local contact email to obtain EAB credentials automatically. The TLS configuration waits 60 seconds before checking DNS propagation. To use Let's Encrypt instead, set `acme.ca` to `https://acme-v02.api.letsencrypt.org/directory`. Only the selected issuer is configured, without a second-CA fallback. Remove the temporary token file after provisioning; Caddy receives the Podman secret as `CF_API_TOKEN`. Rotating the token requires replacing the host Podman secret and recreating the Caddy container.

### Apply, build, and start

Container names no longer use the `my-` prefix. Kimi and Codex now use matching container and service names: `kimi` and `codex`; DSH is added as `dsh`. Before applying this rename or reloading the user manager, stop the old `kimi-web-box.service` and `codex-box.service` from a host terminal so their old units remove the old containers. Stop the other existing workspace services too, and `smb-box.service` if migrating its container name. Named volumes retain their existing names; do not delete them.

After stopping the old services, apply their explicit retirement entries so the old units cannot return on the next reload:

```sh
chezmoi apply \
  ~/.config/containers/systemd/codex-box.container \
  ~/.config/containers/systemd/kimi-web-box.container
```

Review `chezmoi diff` first, then apply only these configuration targets without running unrelated scripts:

```sh
chezmoi apply --include=files \
  ~/.config/caddy/Caddyfile \
  ~/.config/containers/systemd/workspace.pod \
  ~/.config/containers/systemd/dev-box.container \
  ~/.config/containers/systemd/codex.container \
  ~/.config/containers/systemd/kimi.container \
  ~/.config/containers/systemd/dsh.container \
  ~/.config/containers/systemd/caddy.build \
  ~/.config/containers/systemd/caddy.container
systemctl --user daemon-reload
systemctl --user restart box-base-build.service dev-box-build.service caddy-build.service
```

Before starting, inspect `tailscale serve status`: if an existing Serve listener occupies the Tailscale address on HTTPS 443, disable that listener with `tailscale serve --https=443 off` after confirming its current users can tolerate the interruption. Do not reset unrelated Serve listeners.

After successful builds and credential/DNS setup, stop the old containers and start the Pod from the host terminal:

```sh
systemctl --user stop dev-box.service codex.service kimi.service dsh.service caddy.service
systemctl --user start workspace-pod.service
systemctl --user status workspace-pod.service dev-box.service codex.service kimi.service dsh.service caddy.service
```

If the previous `dev.pod` was already deployed, stop `dev-pod.service` and its members from host SSH before applying the rename, remove the obsolete `~/.config/containers/systemd/dev.pod` file, and reload the user manager. Preserve all named volumes. The new Pod is named `workspace`; its generated unit is `workspace-pod.service`.

Quadlet starts members with the Pod. Restart an individual container service to update only that process. Changing Pod network or port publications requires recreating the Pod and its members; do not delete named volumes. SMB is unaffected. Build failures are separate from container failures: fix and retry failed build services explicitly.

### Access and verification

SSH stays on port 2222 at the host Tailscale address. Start notebooks inside dev-box with an explicit published port and keep marimo authentication enabled:

```sh
uv run marimo edit notebook.py --host 0.0.0.0 --port 2718 --no-browser
```

Agents reach notebooks through `127.0.0.1:2718`; remote clients use the host Tailscale address. Only 2718–2720 are reserved for development. These ports belong to the whole Pod, not exclusively dev-box.

Open `https://kimi.workstation.example.com` directly. Kimi retains the existing authentication bypass: anyone allowed to reach that endpoint can submit tasks with the shared user's access. DSH retains native authentication: get its startup URL from `journalctl --user -u dsh.service`, replace the localhost origin with `https://dsh.workstation.example.com`, and preserve the token query. Treat the URL and logs as credentials. Codex pairing and Remote Control keep using the shared `~/.codex`; only codex should own its app server.

Verify from another tailnet device: SSH login, marimo access, Kimi browser/API interaction, and DSH login plus a live session. Inspect `journalctl --user -u caddy.service` for certificate errors. DSH returning 401 without credentials is expected. After verifying new endpoints, remove obsolete per-port Serve listeners with `tailscale serve --https=58627 off` and `tailscale serve --https=3080 off` on the host, if present; do not reset unrelated Serve configuration.

## Image upgrades

The shared development base and Samba image are pinned to Fedora 44 to follow the workstation host. When upgrading Fedora, update the `FROM` tags in `containers/dev-box/Containerfile` and `containers/smb-box/Containerfile` together. Host upgrades do not rebuild these images automatically; Caddy has its own version pin.

On the host, restart `dev-box-build.service`, `box-base-build.service`, and, if enabled, `smb-box-build.service`. Confirm the builds succeed before restarting their consumers: `dev-box.service`, the enabled agent services (`codex`, `kimi`, `dsh`), and `smb-box.service`. Verify SSH, agent connectivity, and [SMB login and file access](../containers/smb-box/README.md) afterward.

## Architecture

`containers/dev-box/Containerfile` builds shared Fedora `box-base` and SSH-enabled `dev-box` stages. Agents use the base and home installations: `~/.local/bin/codex`, `~/.local/bin/kimi`, and `~/.pnpm/bin/dsh`. DSH uses login fish for home-managed Node. Updating an agent requires restarting its container, not rebuilding its image.

The Pod owns the private network, `keep-id` user namespace, and host-compatible hostname. It shares network and UTS only, not PID or IPC. dev-box retains host IPC and GPU devices; other members do not inherit them. Its SSH entrypoint runs as namespace root to prepare persistent host keys, then executes foreground sshd. Agents run as the host user. All containers use a small init and restart after failure.

The four development/agent containers mount home read-write and forward the host SSH agent. Each has a separate SSH volume hiding host private keys; dev-box also mounts `authorized_keys` read-only. All mask host Podman storage. Agents additionally mask Zed server state; dev-box keeps it for Zed. These are cooperative environments, not mutually untrusted tenants: shared home and localhost allow cross-container access. They no longer share host localhost; host-only listeners need a deliberately configured route.

Caddy uses a separate image with a pinned Cloudflare DNS module. Its chezmoi-rendered `~/.config/caddy/Caddyfile` is mounted read-only; no startup script generates configuration. It has no shared-home or SSH-agent mount. Certificates and ACME state persist in `caddy-data`; configuration state uses `caddy-config`. Caddy listens on unprivileged Pod port 8443, mapped to host 443. HTTP redirects and HTTP/3 are disabled, so port 80 and UDP 443 are unnecessary. Its admin API uses a container-local Unix socket rather than the shared localhost.

Reload a changed Caddyfile without restarting other members:

```sh
podman exec caddy caddy reload \
  --config /etc/caddy/Caddyfile --adapter caddyfile \
  --address unix//tmp/caddy-admin.sock
```

If the single-file bind still exposes the old file after chezmoi replaces it, recreate only `caddy.service` instead. Adding a domain requires its DNS record and backend allowed-host configuration; a Caddy route alone does not create A records.
