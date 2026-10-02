# Container services

Optional Linux services run as independent rootless Podman containers. Enable them with `chezmoi init --prompt`; machine-local options are described in [Machine configuration](configuration.md).

| Option | Services |
| --- | --- |
| `services.development` | dev-box, claude-box, Codex, Kimi, DSH, marimo, and secret-proxy |
| `services.smb` | [Samba](../containers/smb-box/README.md) |
| `ingress.caddy` | Private HTTPS through Tailscale |
| `ingress.cloudflared` | Public HTTPS through Cloudflare Tunnel |

## Setup

Use Podman 5.8 or later and run deployment commands from a host terminal. Set `device.tailscale_ipv4` to the address from `tailscale ip -4` and choose a DNS suffix such as `ws.example.com` for `device.domain`. Without a Tailscale address, SSH, Caddy, and SMB publish no host ports. For services to start before login, enable the user's systemd manager at boot; check `loginctl show-user "$USER" -p Linger`.

Rootless Caddy needs `net.ipv4.ip_unprivileged_port_start` at most 443. If the host uses a higher threshold, an administrator must change it before Caddy can bind HTTPS; this host-wide setting is not managed here.

### Encrypted service credentials

Credentials live outside chezmoi in `~/.config/credstore.encrypted`. systemd decrypts them when starting each service. Provision only the enabled services:

| Service | Credential | Contents |
| --- | --- | --- |
| Caddy | `cloudflare-dns-token` | Cloudflare API token with zone read and DNS edit permissions |
| cloudflared | `cloudflared-credentials` | Locally managed Tunnel's JSON credential |
| secret-proxy | `overleaf-token`, `github-token` | Upstream tokens; see [provisioning](../containers/secret-proxy/README.md#deployment) |

The managed [credstore](../home/dot_local/bin/credstore) command creates or replaces a credential with `credstore set NAME` on Linux. It masks terminal input with asterisks, or reads stdin unchanged when piped or redirected. Only encrypted data is written to disk, with private permissions; failed writes preserve the previous credential. For example, provision Caddy's token from a host terminal:

```sh
credstore set cloudflare-dns-token
```

Restart the affected service through `systemctl --user` after rotating a credential. Machine-bound encrypted files alone are not a recovery backup for a replacement host.

### Apply, build, and start

After reviewing the full diff, including scripts and external-package changes, apply the configuration normally:

```sh
chezmoi diff
chezmoi apply
systemctl --user daemon-reload
```

Start the services you enabled with `systemctl --user start <name>.service`; for example, `systemctl --user start kimi.service caddy.service`. Quadlet creates the required networks and runs build dependencies. Complete credential provisioning before starting services that need it.

For later changes, restart affected services to activate new mounts, environment, or network settings. If a Containerfile changed, rebuild its image first with `systemctl --user restart <name>-build.service`, then restart its consumers. Agents and marimo share `box-base`; dev-box has its own image, and claude-box extends it. Applying dotfiles does not itself restart these containers, and disabling a chezmoi option does not stop or remove a deployed service.

In symlink mode, edits to static source files can already be visible on the host before apply. When changing a shared network or a proxy/client interface, stop the affected services together and activate the complete change at a session boundary. Container restarts interrupt agent sessions and notebook kernels. Preserve home and named volumes.

Check `systemctl --user --failed`, `podman ps`, and the affected service's browser or API endpoint after activation. Use `journalctl --user -u <name>.service` for startup errors; logs such as DSH's login URL can contain credentials.

## Private HTTPS

Caddy serves `kimi.<device.domain>`, `dsh.<device.domain>`, and `marimo.<device.domain>` for development services. Create DNS-only A records pointing to the Tailscale address, or a matching wildcard. Do not enable Cloudflare's HTTP proxy for these private names. Caddy manages certificate challenge records, not these service A records.

ZeroSSL is the default issuer and needs `acme.email`. To use another issuer, edit `acme.ca`; reinitialization resets it to ZeroSSL.

Kimi and marimo have no application login on the private network. DSH retains its own login. Limit private access through Tailscale rules.

## Cloudflare Tunnel

cloudflared connects directly to services on the container network; it does not pass through Caddy. With `device.domain = "ws.example.com"`, the public routes are:

| Hostname | Service | Authentication |
| --- | --- | --- |
| `dsh-ws.example.com` | DSH | Access plus DSH login |
| `kimi-ws.example.com` | Kimi | Access |

Ingress is available when development services are enabled. Use a device suffix that produces single-level public hostnames under your Cloudflare zone; a hyphen does not flatten deeper suffixes.

Create a locally managed Tunnel, DNS routes for the enabled hostnames, and one Access application covering the browser hostnames. Supply the Tunnel UUID, Access team name, and application AUD during initialization. cloudflared validates Access JWTs on browser routes; unknown hosts return 404. chezmoi does not create these Cloudflare resources.

Encrypt the Tunnel's JSON credential on the host:

```sh
credstore set cloudflared-credentials < /path/to/tunnel-uuid.json
```

Before relying on public access, check that browser routes require Access and authenticated sessions work. Adding or changing ingress also updates Kimi/DSH host allowlists, so restart those services when their configuration changes.

## Development services

Development containers reuse tools and projects from the shared home directory. Codex, Kimi, DSH, and marimo read common tool paths from `development.env`. Updating a home-installed tool needs a service restart, not an image rebuild. SSH is available through dev-box on the Tailscale address at port 2222.

Claude Desktop connects over SSH to claude-box on the Tailscale address at port 10022, with the same authorized keys as dev-box. Desktop starts and upgrades its remote server inside the container, so sessions can open any folder in the shared home; restarting claude-box ends them. claude-box has agent permissions: gh goes through secret-proxy and other agents' credentials are masked. dev-box is for interactive login and keeps the host's gh login and agent credentials visible, so point Desktop at claude-box rather than dev-box or the host.

Agents delegate through service APIs and hide each other's provider credential files. Containers use the forwarded ssh-agent and trust the host's `~/.ssh/known_hosts` read-only; restart them after replacing that file, for example with `ssh-keygen -R`. Git and gh use [secret-proxy](../containers/secret-proxy/README.md); gh preferences are regenerated automatically from the host config. These are cooperative containers with shared home access, not isolation for mutually untrusted users.

marimo serves `~/Documents` through private HTTPS; containers use `http://marimo:2718`. Its service installs `marimo[sandbox]` with `uv tool install --managed-python` into shared home before startup. Upgrade explicitly with `uv tool upgrade marimo`. Restarting the service stops all notebook kernels. See [environment selection](../agents/skills/marimo-pair/reference/finding-marimo.md#environment-selection) for project venvs and [marimo-pair](../agents/skills/marimo-pair/SKILL.md) for agent access.

## Networks and configuration

| Network | Purpose |
| --- | --- |
| `workspace` | Development services, their callers, Caddy, and cloudflared |
| `secret-proxy` | Trusted development clients to the credential proxy |

Networks retain outbound access and block direct routing between bridges. Containers use service names, not each other's localhost. External HTTPS access goes through Caddy or cloudflared; SSH uses the development containers' published ports.

[Quadlets](../home/dot_config/containers/systemd) own process settings, mounts, permissions, and build dependencies. [Caddy](../home/dot_config/caddy/Caddyfile.tmpl) and [Tunnel](../home/dot_config/cloudflared/config.yml.tmpl) own ingress routes. Keep implementation details and their reasons next to those settings.
