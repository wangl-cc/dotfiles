# Container services

Optional Linux services run as independent rootless Podman containers. Enable them with `chezmoi init --prompt`; machine-local options are described in [Machine configuration](configuration.md).

| Option | Services |
| --- | --- |
| `services.development` | dev-box, Codex, Kimi, DSH, marimo, and secret-proxy |
| `services.llm` | Bifrost and vLLM |
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
| Bifrost | `bifrost.env` | `BIFROST_ENCRYPTION_KEY=<64 hex characters>` |
| secret-proxy | `overleaf-token`, `github-token` | Upstream tokens; see [provisioning](../containers/secret-proxy/README.md#deployment) |

The managed [credstore](../home/dot_local/bin/credstore) command creates or replaces a credential with `credstore set NAME` on Linux. It masks terminal input with asterisks, or reads stdin unchanged when piped or redirected. Only encrypted data is written to disk, with private permissions; failed writes preserve the previous credential. For example, provision Caddy's token from a host terminal:

```sh
credstore set cloudflare-dns-token
```

Restart the affected service through `systemctl --user` after rotating a credential. Keep Bifrost's encryption key stable and back it up with its database; replacing the key alone makes existing encrypted data unreadable. Machine-bound encrypted files alone are not a recovery backup for a replacement host. Bifrost receives its decrypted key through a container environment file, so it also exists in Podman's runtime configuration.

### Apply, build, and start

After reviewing the full diff, including scripts and external-package changes, apply the configuration normally:

```sh
chezmoi diff
chezmoi apply
systemctl --user daemon-reload
```

Start the services you enabled with `systemctl --user start <name>.service`; for example, `systemctl --user start vllm.service bifrost.service caddy.service`. Quadlet creates the required networks and runs build dependencies. Complete credential provisioning before starting services that need it.

For later changes, restart affected services to activate new mounts, environment, or network settings. If a Containerfile changed, rebuild its image first with `systemctl --user restart <name>-build.service`, then restart its consumers. Agents and marimo share `box-base`; dev-box has its own image. Applying dotfiles does not itself restart these containers, and disabling a chezmoi option does not stop or remove a deployed service.

In symlink mode, edits to static source files can already be visible on the host before apply. When changing a shared network or a proxy/client interface, stop the affected services together and activate the complete change at a session boundary. Container restarts interrupt agent sessions and notebook kernels. Preserve home and named volumes.

Check `systemctl --user --failed`, `podman ps`, and the affected service's browser or API endpoint after activation. Use `journalctl --user -u <name>.service` for startup errors; logs such as DSH's login URL can contain credentials.

## Private HTTPS

Caddy serves `kimi.<device.domain>`, `dsh.<device.domain>`, `marimo.<device.domain>`, and `llm.<device.domain>` for the enabled service groups. Create DNS-only A records pointing to the Tailscale address, or a matching wildcard. Do not enable Cloudflare's HTTP proxy for these private names. Caddy manages certificate challenge records, not these service A records.

ZeroSSL is the default issuer and needs `acme.email`. To use another issuer, edit `acme.ca`; reinitialization resets it to ZeroSSL.

Kimi and marimo have no application login on the private network; Bifrost's dashboard also trusts private access. DSH retains its own login. Limit private access through Tailscale rules. Bifrost inference requires a virtual key on both private and public endpoints.

## Cloudflare Tunnel

cloudflared connects directly to services on the container network; it does not pass through Caddy. With `device.domain = "ws.example.com"`, the public routes are:

| Hostname | Service | Authentication |
| --- | --- | --- |
| `llm-ws.example.com` | Bifrost `/v1/models` and `/v1/chat/completions` only | Bifrost virtual key |
| `admin-llm-ws.example.com` | Bifrost dashboard and management API | Cloudflare Access |
| `dsh-ws.example.com` | DSH | Access plus DSH login |
| `kimi-ws.example.com` | Kimi | Access |

Only enabled service groups contribute routes. Use a device suffix that produces single-level public hostnames under your Cloudflare zone; a hyphen does not flatten deeper suffixes.

Create a locally managed Tunnel, DNS routes for the enabled hostnames, and one Access application covering the browser hostnames. Keep the `llm` API hostname outside that browser-login application. Supply the Tunnel UUID, Access team name, and application AUD during initialization. cloudflared validates Access JWTs on browser routes; unknown hosts and unlisted API paths return 404. chezmoi does not create these Cloudflare resources.

Encrypt the Tunnel's JSON credential on the host:

```sh
credstore set cloudflared-credentials < /path/to/tunnel-uuid.json
```

Before relying on public access, check that browser routes require Access, the API rejects missing virtual keys, and valid streaming requests work. Adding or changing ingress also updates Kimi/DSH host allowlists, so restart those services when their configuration changes.

## Local models

Bifrost is the only model gateway; vLLM has no host or ingress port. Issue virtual keys in the Bifrost dashboard, restricted to provider `vllm` and model `hy-mt2-7b`. Clients use `https://llm.<device.domain>/v1` privately or the public API hostname, with standard bearer authorization.

Bifrost keeps configuration and request statistics in the `bifrost-data` volume. Request content logging is disabled. Back up this volume and the encryption key together.

For a fresh database only, generate the encryption credential from Bash:

```bash
set -o pipefail
if [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/credstore.encrypted/bifrost.env" ] && bifrost_key=$(openssl rand -hex 32); then
  printf 'BIFROST_ENCRYPTION_KEY=%s\n' "$bifrost_key" | credstore set bifrost.env
  unset bifrost_key
fi
```

The vLLM image requires Linux x86_64 and a compatible AMD GPU. Before first startup, create its cache directories with `mkdir -p ~/.cache/{huggingface,vllm,triton}`. GPU access currently requires disabling SELinux label separation for this container; the reason is documented beside the setting in its [Quadlet](../home/dot_config/containers/systemd/vllm.container).

## Development services

Development containers reuse tools and projects from the shared home directory. Codex, Kimi, DSH, and marimo read common tool paths from `development.env`. Updating a home-installed tool needs a service restart, not an image rebuild. SSH is available through dev-box on the Tailscale address at port 2222.

Agents delegate through service APIs and hide each other's provider credential files. Git and gh use [secret-proxy](../containers/secret-proxy/README.md); gh preferences are regenerated automatically from the host config. These are cooperative containers with shared home access, not isolation for mutually untrusted users.

marimo serves `~/Documents` through private HTTPS; containers use `http://marimo:2718`. Its service installs `marimo[sandbox]` with `uv tool install --managed-python` into shared home before startup. Upgrade explicitly with `uv tool upgrade marimo`. Restarting the service stops all notebook kernels. See [environment selection](../agents/skills/marimo-pair/reference/finding-marimo.md#environment-selection) for project venvs and [marimo-pair](../agents/skills/marimo-pair/SKILL.md) for agent access.

## Networks and configuration

| Network | Purpose |
| --- | --- |
| `workspace` | Development services, their callers, Caddy, and cloudflared |
| `llm` | Bifrost, Caddy, and cloudflared |
| `inference` | Bifrost to vLLM |
| `secret-proxy` | Trusted development clients to the credential proxy |

Networks retain outbound access and block direct routing between bridges. Containers use service names, not each other's localhost. Neither `workspace` nor `llm` publishes a port; external access goes through Caddy or cloudflared.

Caddy and cloudflared are the only containers joining both `workspace` and `llm`; a multi-homed container does not route between its networks. Bifrost stays off `workspace` because Kimi and marimo there have no application login. If development services later need local models, route them through a Caddy site on `workspace` that proxies only inference paths to Bifrost, rather than adding clients to `llm`.

[Quadlets](../home/dot_config/containers/systemd) own process settings, mounts, permissions, and build dependencies. [Caddy](../home/dot_config/caddy/Caddyfile.tmpl) and [Tunnel](../home/dot_config/cloudflared/config.yml.tmpl) own ingress routes. Keep implementation details and their reasons next to those settings.
