# Secret proxy

A small HTTP reverse proxy that adds credentials for fixed HTTPS upstreams. It runs in the workspace Pod so Git and other clients can authenticate without receiving credential files. It uses only the Go standard library. Overleaf is the first configured service; routing and authentication are not specific to Overleaf.

The Linux host owns encrypted credentials and delivers plaintext files only to this container through systemd. Other workspace containers connect to `127.0.0.1:8787`. No host port is published, and no Podman secret store is used for this proxy.

## Configuration

The managed configuration is [`home/dot_config/secret-proxy/config.json`](../../home/dot_config/secret-proxy/config.json). It contains upstreams and credential filenames, never credential values. Each service accepts exactly one of these authentication forms:

```json
{
  "listen": "127.0.0.1:8787",
  "services": {
    "overleaf": {
      "upstream": "https://git.overleaf.com",
      "auth": {
        "type": "basic",
        "username": "git",
        "credential": "overleaf-token"
      }
    },
    "api": {
      "upstream": "https://api.example.com/v1",
      "auth": {
        "type": "bearer",
        "credential": "api-token"
      }
    },
    "other": {
      "upstream": "https://other.example.com",
      "auth": {
        "type": "header",
        "header": "X-Api-Key",
        "credential": "other-key"
      }
    }
  }
}
```

`http://127.0.0.1:8787/overleaf/PROJECT_ID` forwards to `https://git.overleaf.com/PROJECT_ID`. The service name is removed; the rest of the path, escaping, and query string are retained. An upstream URL may include a base path. A service grants access to the configured upstream using that credential's existing permissions; this version does not add per-project or per-method authorization.

The listener must be a numeric loopback address with a port from 1 to 65535. Service and credential names accept ASCII letters, digits, `.`, `_`, and `-`, excluding `.` and `..`. Credentials are files beneath `-credentials-dir`, which defaults to `$CREDENTIALS_DIRECTORY`. One final LF or CRLF is removed; other control characters, empty credentials, and files over 64 KiB are rejected. All configured credentials must be readable before the listener starts.

Basic, Bearer, and custom header authentication are compiled into one header per service at startup. Incoming `Authorization`, `Proxy-Authorization`, and cookies are removed, then the configured authentication header is replaced. Response authentication headers and cookies are removed from both headers and trailers. Response bodies are passed through without inspection; this is not a filter for secrets that an upstream application itself returns in its content.

Upstreams require verified HTTPS without URL credentials, queries, or fragments. Proxy environment variables are ignored. Redirects with a `Location` header fail with HTTP 502, so configure the final upstream address. CONNECT, protocol upgrades, OAuth refresh, and request signing are unsupported. Unknown routes return 404; upstream failures return a generic 502 without logging request URLs, headers, credentials, or detailed transport errors.

Requests and responses stream without whole-body buffering. The default request deadline is 10 minutes, including server processing and transfer; adjust it with `-request-timeout`. Client cancellation cancels the upstream request. SIGTERM stops accepting requests and allows up to 10 seconds for active requests to finish before closing them. Credential changes require restarting the service.

## Build and test

Run from this directory with Go 1.27 or later:

```sh
go test -race ./...
go vet ./...
go build -trimpath -o /tmp/secret-proxy .
```

Tests use temporary fake credentials and local TLS servers. If Git and its HTTP backend are installed, the suite also performs a real smart-HTTP push and clone without giving credentials to the Git client. That test is skipped when Git is unavailable.

The multi-stage `Containerfile` pins the Go builder version, runs tests, and copies a static binary and CA certificates into a `scratch` runtime image. It does not require a Go installation on the host. From the repository root:

```sh
podman build -t localhost/secret-proxy containers/secret-proxy
```

## Host setup and credential preflight

Use a Linux host with systemd 258 or later and the workspace's Podman 5.8 or later. This recipe targets per-user encrypted credentials; the availability of the `systemd-creds --user` CLI alone does not validate the complete service-to-container handoff. The host must provide `systemd-creds.socket` and support its selected encryption backend. Run lifecycle and provisioning commands from a host terminal, not from an agent container.

The user manager must run at boot for unattended operation. Check its state with `loginctl show-user "$USER" -p Linger`; if necessary, enable it with `loginctl enable-linger "$USER"` according to the host's administration policy.

Review the full `chezmoi diff`, then apply the new configuration files:

```sh
chezmoi cat ~/.config/secret-proxy/config.json
chezmoi cat ~/.config/secret-proxy/gitconfig
chezmoi cat ~/.config/containers/systemd/secret-proxy.container
chezmoi cat ~/.config/containers/systemd/secret-proxy.build
chezmoi diff
chezmoi apply --include=dirs,files,symlinks \
  ~/.config/secret-proxy \
  ~/.config/containers/systemd/secret-proxy.container \
  ~/.config/containers/systemd/secret-proxy.build
systemctl --user daemon-reload
systemctl --user start secret-proxy-build.service
```

Before provisioning a real token, check automatic decryption and the rootless credential mount using a fake token. The following Bash commands create an isolated temporary credential, start a transient user service, and run the proxy's configuration check with networking disabled. No credential value is printed:

```bash
set -o pipefail
secret_proxy_check_dir=$(mktemp -d "$XDG_RUNTIME_DIR/secret-proxy-check.XXXXXX")
printf '%s' 'dummy-preflight-token' | systemd-creds encrypt --user \
  --name=overleaf-token - "$secret_proxy_check_dir/overleaf-token.cred"
systemd-run --user --wait --pipe --collect --expand-environment=no \
  --property="LoadCredentialEncrypted=overleaf-token:$secret_proxy_check_dir/overleaf-token.cred" \
  /bin/sh -ec 'exec podman run --rm --network=none --userns=keep-id \
    --security-opt=label=disable \
    --volume="$CREDENTIALS_DIRECTORY:/run/credentials:ro" \
    --volume="$HOME/.config/secret-proxy/config.json:/etc/secret-proxy/config.json:ro" \
    localhost/secret-proxy -credentials-dir /run/credentials -check'
rm "$secret_proxy_check_dir/overleaf-token.cred"
rmdir "$secret_proxy_check_dir"
```

A successful run reports `configuration and credentials valid (1 services)`. If decryption or the bind mount fails, resolve that host prerequisite before using a real credential. The check does not call Overleaf and does not change an existing service or credential.

## Provision and use Overleaf

[Create an Overleaf Git token](https://docs.overleaf.com/integrations-and-add-ons/git-integration-and-github-synchronization/git/git-integration-authentication-tokens). Enter it at the host password prompt below. The prompt and encryption command communicate through a pipe; the token is not an argument, an environment variable, a source file, or a plaintext file on disk. These Bash commands also work for rotation; the encrypted file is replaced only if the pipeline succeeds:

```bash
set -o pipefail
umask 077
install -d -m 700 "$HOME/.config/secret-proxy/credentials"
if systemd-ask-password -n 'Overleaf Git token:' | systemd-creds encrypt --user \
  --name=overleaf-token - "$HOME/.config/secret-proxy/credentials/overleaf-token.cred.new"; then
  mv "$HOME/.config/secret-proxy/credentials/overleaf-token.cred.new" \
    "$HOME/.config/secret-proxy/credentials/overleaf-token.cred"
fi
```

The proxy's Quadlet loads the encrypted file through `[Service] LoadCredentialEncrypted=`. Its `[Container] Volume=%d:/run/credentials:ro` explicitly mounts the generated service's credential directory into the proxy, with the Pod's `keep-id` mapping and the host UID/GID. `Secret=` is a different Podman mechanism and is not involved. systemd encrypts for this user and host; retain a way to reissue credentials when replacing the machine or OS installation.

The source configurations for `dev-box`, `codex`, `kimi`, and `dsh` mask `~/.config/secret-proxy/credentials` in addition to their existing masks. They also mount the managed [`gitconfig`](../../home/dot_config/secret-proxy/gitconfig) read-only at `/etc/gitconfig`. Git in these containers rewrites both `https://git.overleaf.com/` and `https://git@git.overleaf.com/` to the proxy; repository remotes retain their original URLs. The host and macOS do not load this container-only configuration. If the proxy is unavailable, these requests fail without falling back to a direct connection.

After reviewing `chezmoi cat` for each affected Quadlet and the full `chezmoi diff`, apply the client configuration:

```sh
chezmoi apply --include=dirs,files,symlinks \
  ~/.config/secret-proxy/gitconfig \
  ~/.config/containers/systemd/dev-box.container \
  ~/.config/containers/systemd/codex.container \
  ~/.config/containers/systemd/kimi.container \
  ~/.config/containers/systemd/dsh.container
systemctl --user daemon-reload
```

Once the proxy is running, recreate the affected client containers from a host session when interruptions are acceptable, using `systemctl --user restart NAME.service` for each active client. This reconnects SSH and agent sessions; no image rebuild is needed. Updating Quadlet files alone does not update mounts in running containers. Keep the proxy's plaintext credential mount out of every client container. This arrangement prevents routine reading of credential files by agents; it does not try to defend against a malicious actor who can change the host's user configuration.

The proxy is skipped until its encrypted Overleaf credential exists. Once provisioned, start the existing workspace Pod if needed, then:

```sh
systemctl --user start secret-proxy.service
systemctl --user status secret-proxy.service
```

From a recreated workspace client container, verify that the rewrite comes from `/etc/gitconfig`, then test the actual project using its original URL:

```sh
git config --show-origin --get-all url.http://127.0.0.1:8787/overleaf/.insteadOf
git ls-remote https://git.overleaf.com/PROJECT_ID
```

Replace `PROJECT_ID` with the project's Git ID. New clones can also use the original HTTPS URL. If a remote was previously changed to the localhost URL, restore it with `git remote set-url overleaf https://git.overleaf.com/PROJECT_ID`. After rotating a credential, use `systemctl --user restart secret-proxy.service`; no Pod recreation or client-container restart is needed for subsequent rotations. Verify a reboot separately to establish unattended startup on the actual host.

Adding another service requires its non-secret configuration entry and a matching `LoadCredentialEncrypted=` entry in the Quadlet. The initial condition on `overleaf-token.cred` reflects this deployment's first service. Keep credential files outside chezmoi source control; future services use the same proxy code and credential mount.

References: [systemd credentials](https://systemd.io/CREDENTIALS/), [systemd-creds](https://github.com/systemd/systemd/blob/v258/man/systemd-creds.xml), and [Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html).
