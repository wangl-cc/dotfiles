# Development containers

The development Pod groups `dev-box`, `codex`, `kimi`, `dsh`, `marimo`, `caddy`, and the optional `secret-proxy` on one private network. dev-box provides SSH and the interactive compute environment; the agents run from installations in the shared home. Caddy exposes Kimi, DSH, and marimo at `https://kimi.workstation.example.com`, `https://dsh.workstation.example.com`, and `https://marimo.workstation.example.com`. The [secret proxy](../containers/secret-proxy/README.md) provides HTTP authentication at the Pod's `127.0.0.1:8787`, with credentials delivered only to its container; it remains inactive until provisioned. SMB remains independent.

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

The Pod publishes only TCP 2222 for SSH and TCP 443 for Caddy, on localhost and the configured Tailscale IPv4. marimo listens on Pod-local `127.0.0.1:2718`; no notebook port is published to the host. Check for port conflicts and wait for Tailscale to have its address before startup:

```sh
tailscale ip -4
ss -ltn
sysctl net.ipv4.ip_unprivileged_port_start
```

Rootless Podman needs `net.ipv4.ip_unprivileged_port_start` at most 443. If it is higher, an administrator must deliberately permit low-port binding before deployment. For example, `sudo sysctl -w net.ipv4.ip_unprivileged_port_start=443` changes it until reboot; persistence belongs in host `/etc/sysctl.d/`. This permits all unprivileged host users to bind available ports 443–1023, not just this Pod. The repository does not apply this host-wide change automatically.

### Cloudflare DNS and credentials

Create a Cloudflare API Token scoped to `example.com` with `Zone:Read` and `DNS:Edit`. Keep the raw token in a mode-0600 file outside the repository, preferably temporarily in the host runtime directory. Do not put it in the Caddyfile, shell history, or a committed environment file. Replace `/path/to/token` below with that file.

In the Cloudflare `example.com` zone, manually create a DNS-only wildcard A record named `*.workstation` pointing to the host Tailscale IPv4, or separate A records named `kimi.workstation`, `dsh.workstation`, and `marimo.workstation`. These names correspond to `kimi.<device.domain>`, `dsh.<device.domain>`, and `marimo.<device.domain>`; adjust them together if changing the suffix. Do not enable Cloudflare's HTTP proxy.

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
chezmoi apply --include=files,symlinks \
  ~/.config/caddy/Caddyfile \
  ~/.config/containers/systemd/workspace.pod \
  ~/.config/containers/systemd/dev-box.container \
  ~/.config/containers/systemd/codex.container \
  ~/.config/containers/systemd/kimi.container \
  ~/.config/containers/systemd/dsh.container \
  ~/.config/containers/systemd/marimo.container \
  ~/.config/containers/systemd/caddy.build \
  ~/.config/containers/systemd/caddy.container
systemctl --user daemon-reload
systemctl --user restart box-base-build.service dev-box-build.service caddy-build.service
```

Before starting, inspect `tailscale serve status`: if an existing Serve listener occupies the Tailscale address on HTTPS 443, disable that listener with `tailscale serve --https=443 off` after confirming its current users can tolerate the interruption. Do not reset unrelated Serve listeners.

After successful builds and credential/DNS setup, stop the old containers and start the Pod from the host terminal:

```sh
systemctl --user stop dev-box.service codex.service kimi.service dsh.service marimo.service caddy.service
systemctl --user start workspace-pod.service
systemctl --user status workspace-pod.service dev-box.service codex.service kimi.service dsh.service marimo.service caddy.service
```

If the previous `dev.pod` was already deployed, stop `dev-pod.service` and its members from host SSH before applying the rename, remove the obsolete `~/.config/containers/systemd/dev.pod` file, and reload the user manager. Preserve all named volumes. The new Pod is named `workspace`; its generated unit is `workspace-pod.service`.

Quadlet starts members with the Pod. Restart an individual container service to update only that process. Changing Pod network or port publications requires recreating the Pod and its members; do not delete named volumes. SMB is unaffected. Build failures are separate from container failures: fix and retry failed build services explicitly.

### Access and verification

SSH stays on port 2222 at the host Tailscale address. Open `https://marimo.workstation.example.com` for the shared notebook browser rooted at `~/Documents`. `marimo.service` owns the server and its notebook kernels in a separate container. The Quadlet starts a pinned `marimo[sandbox]` tool environment directly through `uvx`; first startup may download packages. marimo uses `--no-token`: access is controlled by Tailscale's network rules, while Caddy provides HTTPS. Anyone permitted to reach the service can execute notebook code and access files available to the container user. The former token file and launcher are retired through chezmoi's removal list.

Agents in the workspace Pod use `http://127.0.0.1:2718` without a token. A host process must use the HTTPS URL because the host does not share Pod localhost. Each notebook session has its own kernel; restarting a kernel through the notebook menu leaves other sessions and the server running. Restarting `marimo.service` stops all its kernels.

The server runs in directory sandbox mode. PEP 723 notebooks use their inline dependencies unless an existing environment is explicitly selected. In marimo 0.24.0, project configuration is loaded only from the server startup path: a server rooted at `~/Documents` does not discover each notebook's project `pyproject.toml`. To select an existing project environment, put the following in the notebook's PEP 723 header (merge it into an existing header rather than adding a second one):

```python
# /// script
# [tool.marimo.venv]
# path = "../.venv"
# writable = false
# ///
```

This relative path resolves from the notebook directory. The example fits `project/notebooks/example.py` with `project/.venv`; adjust it for notebooks at other depths. Prepare compatible marimo and IPC dependencies in each project environment; this configuration does not run `uv sync`. Keep server and kernel marimo versions aligned. Different Python versions require each environment to provide its own marimo, msgspec, and pyzmq; the fallback that injects these packages from the server requires matching Python versions. uv selects the server interpreter; uv-managed interpreters are available through shared home. Existing venvs pointing at `/usr/bin/python3` still require a compatible system interpreter in the shared base image. Native extensions also require their system libraries in this container: mounting a `.venv` does not provide libraries installed only in dev-box or on the host.

`writable = false` is not a complete read-only guarantee in the inspected marimo 0.24 behavior. Missing-package or UI installation can still modify the selected project `.venv`, and sandbox dependency recording can write `dependencies` into the notebook without updating the project's `pyproject.toml` or `uv.lock`. The notebook still runs in the selected `.venv`; the presence of inline dependencies does not mean it also has a second sandbox. For project-owned dependencies, use the project's normal `uv add` and synchronization workflow instead of notebook package installation. `uv add --script notebook.py` updates inline metadata, not project metadata. Inspect the active kernel's interpreter and package locations when diagnosing where an installation went. A later project `uv sync` may remove packages absent from the project lockfile.

The [marimo-pair skill](../agents/skills/marimo-pair/SKILL.md) connects to the shared server and selects active notebook sessions by path or session ID. Its default URL is `https://marimo.ws.loongw.cc`; set `MARIMO_URL` for another device or use `--port 2718` from inside the workspace Pod. It does not launch additional project servers. Moving project notebooks, local native packages, or import hooks into independent sandboxes requires separate configuration and verification; deployment of this server does not perform that migration.

To migrate existing direct-port servers, first verify their active sessions and save work. Apply the focused marimo, Caddy, and Pod targets, including removal of the retired `~/.config/containers/systemd/marimo.build`. marimo reuses `box-base.build`; no separate marimo image build is needed. Once Pod port 2718 is free, run the following from the host to update only the two services:

```sh
systemctl --user daemon-reload &&
systemctl --user restart marimo.service caddy.service
```

Verify HTTPS access, open two lightweight notebooks, confirm their interpreters and independent kernel restart, and test agent pairing. Defer the workspace Pod restart until the other sessions can be interrupted. The already-running Pod retains its old port publications even after applying the new Pod file; neither a Caddy restart nor a user-manager reload removes them. A later `systemctl --user restart workspace-pod.service` from a host terminal recreates the Pod and its members with only SSH and HTTPS published. Preserve named volumes and verify the actual infra container's `podman port` output and host listeners afterward.

Open `https://kimi.workstation.example.com` directly. Kimi retains the existing authentication bypass: anyone allowed to reach that endpoint can submit tasks with the shared user's access. DSH retains native authentication: get its startup URL from `journalctl --user -u dsh.service`, replace the localhost origin with `https://dsh.workstation.example.com`, and preserve the token query. Treat the URL and logs as credentials. Codex pairing and Remote Control keep using the shared `~/.codex`; only codex should own its app server.

Verify from another tailnet device: SSH login, marimo access, Kimi browser/API interaction, and DSH login plus a live session. Inspect `journalctl --user -u caddy.service` for certificate errors. DSH returning 401 without credentials is expected. After verifying new endpoints, remove obsolete per-port Serve listeners with `tailscale serve --https=58627 off` and `tailscale serve --https=3080 off` on the host, if present; do not reset unrelated Serve configuration.

## Image upgrades

The shared development base and Samba image are pinned to Fedora 44 to follow the workstation host. When upgrading Fedora, update the `FROM` tags in `containers/dev-box/Containerfile` and `containers/smb-box/Containerfile` together. Host upgrades do not rebuild these images automatically; Caddy has its own version pin.

On the host, restart `dev-box-build.service`, `box-base-build.service`, and, if enabled, `smb-box-build.service`. Confirm the builds succeed before restarting their consumers: `dev-box.service`, the enabled agent services (`codex`, `kimi`, `dsh`), and `smb-box.service`. Verify SSH, agent connectivity, and [SMB login and file access](../containers/smb-box/README.md) afterward.

## Architecture

`containers/dev-box/Containerfile` builds shared Fedora `box-base` and SSH-enabled `dev-box` stages. Agents and marimo use the base and home installations: `~/.local/bin/codex`, `~/.local/bin/kimi`, `~/.pnpm/bin/dsh`, and `~/.local/bin/uvx`. DSH uses login fish for home-managed Node. Updating an agent requires restarting its container, not rebuilding its image. marimo has its own service; its Quadlet pins the server package version independently of project environments.

The Pod owns the private network, `keep-id` user namespace, and host-compatible hostname. It shares network and UTS only, not PID or IPC. dev-box retains host IPC and GPU devices; other members do not inherit them. Its SSH entrypoint runs as namespace root to prepare persistent host keys, then executes foreground sshd. Agents run as the host user. All containers use a small init and restart after failure.

The four development/agent containers mount home read-write and forward the host SSH agent. Each has a separate SSH volume hiding host private keys; dev-box also mounts `authorized_keys` read-only. All mask host Podman storage. Agents additionally mask Zed server state; dev-box keeps it for Zed. These are cooperative environments, not mutually untrusted tenants: shared home and localhost allow cross-container access. They no longer share host localhost; host-only listeners need a deliberately configured route.

The marimo container also mounts home read-write for notebooks and project environments, but masks `.ssh`, host Podman storage, Zed server state, and secret-proxy credentials. It does not forward an SSH agent. Its private 256 MiB shared-memory mount supports kernel IPC without sharing the host IPC namespace.

Caddy uses a separate image with a pinned Cloudflare DNS module. Its chezmoi-rendered `~/.config/caddy/Caddyfile` is mounted read-only; no startup script generates configuration. It has no shared-home or SSH-agent mount. Certificates and ACME state persist in `caddy-data`; configuration state uses `caddy-config`. Caddy listens on unprivileged Pod port 8443, mapped to host 443. HTTP redirects and HTTP/3 are disabled, so port 80 and UDP 443 are unnecessary. Its admin API uses a container-local Unix socket rather than the shared localhost.

Reload a changed Caddyfile without restarting other members:

```sh
podman exec caddy caddy reload \
  --config /etc/caddy/Caddyfile --adapter caddyfile \
  --address unix//tmp/caddy-admin.sock
```

If the single-file bind still exposes the old file after chezmoi replaces it, recreate only `caddy.service` instead. Adding a domain requires its DNS record and backend allowed-host configuration; a Caddy route alone does not create A records.
