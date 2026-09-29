# Secret proxy

A small Go HTTP reverse proxy that injects credentials for configured HTTPS hosts and forwards other destinations without credentials. An HTTP path adapter and a GitHub CLI socket adapter normalize requests into a target host, path, and query, then share one credential table. The Linux deployment gives trusted clients access to upstream services without exposing credential files.

## Configuration

See the managed [configuration](../../home/dot_config/secret-proxy/config.json.tmpl) for the complete endpoint and upstream definitions.

- `endpoints` pairs an `adapter` with its `address`: `http` listens on TCP and extracts the destination from `/host/path`; `gh` listens on a Unix socket and extracts it from HTTP `Host`.
- Both adapters preserve the upstream path, query, method, and body. Hostnames are case-insensitive with optional port 443. Encoded hosts and other ports are rejected.
- `upstreams` maps exact hostnames to their credentials. Unmatched hosts are forwarded without credentials; the table may be empty. Requests always go to `https://host` with the adapted path and query.
- Optional `auth` selects `basic`, `bearer`, or a custom `header`, using a `credential` filename. Without it, the upstream receives no proxy credential. Client authentication headers and cookies are stripped before forwarding.
- HTTPS redirects return through the originating adapter, with credentials selected again for each target. Download hosts need no configuration. HTTP downgrades, URL userinfo, non-443 ports, CONNECT, and protocol upgrades are rejected.

Credentials are read at startup from `-credentials-dir` (default: `$CREDENTIALS_DIRECTORY`). One final LF or CRLF is removed. `-check` validates configuration and credentials without listening; address validity and availability are checked when listeners start. Requests stream without a total-duration limit and stop when the client disconnects. Connection establishment, idle connections, and service shutdown remain bounded.

## Build and test

From this directory, with Go 1.27 or later:

```sh
go test -race ./...
go vet ./...
```

From the repository root:

```sh
podman build -t localhost/secret-proxy containers/secret-proxy
podman build --target test --no-cache containers/secret-proxy
```

Normal builds skip the independent test stage. The final `scratch` image contains only the binary and CA certificates; test artifacts stay in the test stage or host build cache. Tests use fake credentials and local servers. The Git push/clone test requires Git and its HTTP backend, so it is skipped in the minimal container test stage.

## Clients

Overleaf uses `http://secret-proxy:8787/git.overleaf.com/`. The container-only [Git configuration](../../home/dot_config/secret-proxy/gitconfig) rewrites original Overleaf URLs to this address. dev-box, Codex, Kimi, and DSH share the dedicated `secret-proxy` network; membership grants access without an additional client token. The proxy has no published host port or ingress route.

GitHub CLI uses `/run/secret-proxy/proxy.sock`. Codex, Kimi, and DSH overlay `~/.config/gh` with the proxy configuration and set the non-secret `GH_TOKEN=proxy-placeholder`. Their real host `hosts.yml` is hidden. Only `api.github.com` and `uploads.github.com` receive the GitHub token; downloads use the same socket without receiving it. The ordinary [gh config](../../home/dot_config/gh/config.yml) remains the source of preferences. `gh-config.path` watches it; `gh-config.service` copies it and appends the socket setting into `%t/gh-config/config.yml`. Agent units require initial generation before starting. The generated directory is mounted read-only over their gh configuration directory; atomic file replacement updates subsequent gh invocations without restarting containers. Keep `http_unix_socket` out of the ordinary host config, since the generator supplies it. Git subprocesses and third-party extensions may use separate transports.

Both endpoints allow HTTPS forwarding to unconfigured hosts and grant access to every configured credential. They are alternative client interfaces, not separate authorization boundaries or an outbound domain allowlist. The socket directory is preserved across service restarts so existing client mounts remain usable. Host administrators remain trusted; this proxy is not per-repository or per-method authorization.

## Deployment

Enable `services.development` on a Linux host with rootless Podman and systemd user encrypted-credential support. The [Quadlet](../../home/dot_config/containers/systemd/secret-proxy.container) requires both `overleaf-token` and `github-token` in `~/.config/credstore.encrypted`. Use the managed `credstore` command from a host terminal to enter each token with asterisk masking:

```sh
credstore set overleaf-token
credstore set github-token
```

systemd decrypts credentials for the service and mounts them only into the proxy at `/run/credentials:ro,Z`. SELinux isolation stays enabled. The rendered configuration is a regular file so private relabeling works. Development containers mask the encrypted credential directory. User/host-bound encrypted files require a recovery or reissue plan when replacing the host.

After provisioning both credentials, review and apply the dotfiles, then rebuild and activate from a host session:

```sh
chezmoi diff
chezmoi apply
systemctl --user daemon-reload
systemctl --user restart secret-proxy-build.service
systemctl --user restart secret-proxy.service
```

Recreate affected clients to activate changed mounts and environment; this interrupts agent sessions. Credential rotations need only a proxy restart. See the [container guide](../../docs/containers.md#apply-build-and-start) for the shared deployment workflow.

From a client, verify `git ls-remote https://git.overleaf.com/PROJECT_ID` and `gh api user`. These checks validate real upstream access, which fake-credential tests cannot establish. For unattended startup, ensure the user manager is enabled at boot (`loginctl show-user "$USER" -p Linger`).
