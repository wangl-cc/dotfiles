# Container services

Optional Linux services run as independent rootless Podman containers. Enable them with `chezmoi init --prompt`; machine-local options are described in [Machine configuration](configuration.md).

| Option | Services |
| --- | --- |
| `services.development` | dev-box, Claude, Codex, Kimi, DSH, marimo, and secret-proxy |
| `services.smb` | [Samba](../containers/smb-box/README.md) |
| `ingress.caddy` | Private HTTPS through Tailscale |

## Setup

Use Podman 5.8 or later and run deployment commands from a host terminal. Set `device.tailscale_ipv4` to the address from `tailscale ip -4` and choose a DNS suffix such as `ws.example.com` for `device.domain`. Without a Tailscale address, SSH, Caddy, and SMB publish no host ports. For services to start before login, enable the user's systemd manager at boot; check `loginctl show-user "$USER" -p Linger`.

Rootless Caddy needs `net.ipv4.ip_unprivileged_port_start` at most 443. If the host uses a higher threshold, an administrator must change it before Caddy can bind HTTPS; this host-wide setting is not managed here.

### Encrypted service credentials

Credentials live outside chezmoi in `~/.config/credstore.encrypted`. systemd decrypts them when starting each service. Provision only the enabled services:

| Service | Credential | Contents |
| --- | --- | --- |
| Caddy | `cloudflare-dns-token` | Cloudflare API token with zone read and DNS edit permissions |
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

For later changes, restart affected services to activate new mounts, environment, or network settings. If a Containerfile changed, rebuild its image first with `systemctl --user restart <name>-build.service`, then restart its consumers. Agents and marimo share `box-base`; dev-box has its own image. Applying dotfiles does not itself restart these containers, and disabling a chezmoi option does not stop or remove a deployed service.

In symlink mode, edits to static source files can already be visible on the host before apply. When changing a shared network or a proxy/client interface, stop the affected services together and activate the complete change at a session boundary. Container restarts interrupt agent sessions and notebook kernels. Preserve home and named volumes.

Check `systemctl --user --failed`, `podman ps`, and the affected service's browser or API endpoint after activation. Use `journalctl --user -u <name>.service` for startup errors; logs such as DSH's login URL can contain credentials.

## Private HTTPS

Caddy connects directly to services on the container network and publishes HTTPS only on the configured Tailscale address. With `device.domain = "ws.example.com"`, the routes are:

| Hostname | Service | Authentication |
| --- | --- | --- |
| `dsh.ws.example.com` | DSH | Tailscale access rules plus DSH login |
| `kimi.ws.example.com` | Kimi | Tailscale access rules |
| `marimo.ws.example.com` | marimo | Tailscale access rules |

Ingress is available when development services are enabled. Create DNS-only A records pointing to the Tailscale address, or a matching wildcard. Do not enable Cloudflare's HTTP proxy for these private names. Caddy manages certificate challenge records, not these service A records. Cloudflare hosts DNS and answers ACME challenges; application traffic travels over Tailscale without Cloudflare Tunnel or Access.

ZeroSSL is the default issuer and needs `acme.email`. To use another issuer, edit `acme.ca`; reinitialization resets it to ZeroSSL.

Kimi and marimo have no application login on the private network. DSH retains its own login. Limit access through Tailscale rules. Adding or changing ingress also updates Kimi/DSH host allowlists, so restart those services when their configuration changes.

## Development services

Development containers reuse tools and projects from the shared home directory. Claude, Codex, Kimi, DSH, and marimo read common tool paths from `development.env`. Updating a home-installed tool needs a service restart, not an image rebuild. SSH is available through dev-box on the Tailscale address at port 2222.

Claude runs one [Remote Control](https://code.claude.com/docs/en/remote-control) server per project as `claude@<project>.service`. Sessions are opened and driven from claude.ai/code, the Claude mobile app, or Claude Desktop over an outbound connection; no port is published. Each instance serves `~/Documents/<project>` unless a `claude@<project>.container.d` drop-in sets another directory, as the chezmoi instance does. The managed instances are `chezmoi`, `ecDNA`, and `pheno-geno`. Start another project under `~/Documents` with `systemctl --user start claude@<project>.service`; to keep one across boots, add an instance symlink beside the others.

Every session of an instance starts in its project directory with auto permission mode, agent permissions, and the host's Claude login: gh goes through secret-proxy and other agents' credentials are masked. The server cannot ask for workspace trust, so run `claude` once in a new project directory before starting its instance. Restarting an instance interrupts its sessions; they return when it comes back within about four hours. dev-box is for interactive login and keeps the host's gh login and agent credentials visible, so prefer an instance over running Claude there.

claude-box, the earlier SSH entry for Claude Desktop, has been removed. Applying dotfiles deletes its Quadlets but not a deployed service: stop `claude-box.service`, run `systemctl --user daemon-reload`, then remove the `claude-box-remote`, `claude-box-ssh`, and `claude-box-data` volumes and the `localhost/fedora-claude-box` image.

Agents delegate through service APIs and hide each other's provider credential files. Containers use the forwarded ssh-agent and trust the host's `~/.ssh/known_hosts` read-only; restart them after replacing that file, for example with `ssh-keygen -R`. Git and gh use [secret-proxy](../containers/secret-proxy/README.md); gh preferences are regenerated automatically from the host config. These are cooperative containers with shared home access, not isolation for mutually untrusted users.

marimo serves `~/Documents` through private HTTPS when Caddy is enabled; containers use `http://marimo:2718`. Its service installs `marimo[sandbox]` with `uv tool install --managed-python` into shared home before startup. Upgrade explicitly with `uv tool upgrade marimo`. Restarting the service stops all notebook kernels. See [environment selection](../agents/skills/marimo-pair/reference/finding-marimo.md#environment-selection) for project venvs and [marimo-pair](../agents/skills/marimo-pair/SKILL.md) for agent access.

## Networks and configuration

| Network | Purpose |
| --- | --- |
| `workspace` | Development services, their callers, and Caddy |
| `secret-proxy` | Trusted development clients to the credential proxy |

Networks retain outbound access and block direct routing between bridges. Containers use service names, not each other's localhost. External HTTPS access goes through Caddy on Tailscale; SSH uses the development containers' published ports on Tailscale.

[Quadlets](../home/dot_config/containers/systemd) own process settings, mounts, permissions, and build dependencies. The [Caddy configuration](../home/dot_config/caddy/Caddyfile.tmpl) owns ingress routes. Keep implementation details and their reasons next to those settings.
