# Development containers

These Fedora-based development containers separate the interactive environment from long-running agents. `dev-box` provides SSH access, `codex-box` runs Codex Remote Control, and `kimi-web-box` runs Kimi's browser UI and API. They share the host user's development files while retaining separate processes and service lifecycles.

## Related operations

Container lifecycle commands run on the host. After changing the container sources or their chezmoi data, render the managed systemd files and reload the user units:

```sh
chezmoi apply ~/.config/containers/systemd
systemctl --user daemon-reload
```

Build and restart each container independently when it is needed:

```sh
systemctl --user restart dev-box-build.service
systemctl --user restart dev-box.service

systemctl --user restart box-base-build.service
systemctl --user restart codex-box.service
systemctl --user restart kimi-web-box.service
```

The build service updates the image; it does not replace an already-running container. Restart the corresponding container service after its build completes. Both build services are capped at 15 minutes.

## Architecture

### Images and processes

`boxes/dev-box/Containerfile` builds a shared `box-base` stage from `registry.fedoraproject.org/fedora:44`. The Fedora release follows the host's release; see the [container upgrade policy](../README.md#containers). The base installs the common command-line and build tools, creates the configured user, and provides `/var/home` as a compatibility link to `/home` for absolute paths created on Fedora Atomic hosts. The `dev-box` target adds `openssh-server` and starts `/usr/local/sbin/dev-box-run`. That entrypoint prepares the persistent SSH host keys, validates `sshd`, and replaces itself with `sshd -D -e`, so `sshd` is the container's long-running process.

`codex-box` uses the `box-base` image directly; there is no Codex-specific image stage. Its Quadlet unit selects the configured user and home working directory, then runs `/home/<user>/.local/bin/codex app-server --remote-control --listen unix://` from the shared home. The host must provide a working Linux Codex installation, including its companion binaries and resources, at that entry point. `kimi-web-box` uses the same image and runs the host's `~/.local/bin/kimi web` in the foreground. All three containers use `RunInit=true` and restart after failure with a five-second delay.

### Storage and access boundaries

`dev-box` uses the host network and IPC namespaces; its `sshd` listens on port 2222 in the shared host network namespace. It mounts the host home directory at `/home/<user>`, while the ordinary named volume `dev-box-ssh` overlays the host `~/.ssh`, the host `authorized_keys` remains available read-only for inbound login, and outbound SSH authentication uses the host agent socket. It receives `/dev/kfd` and `/dev/dri`, uses an unconfined seccomp profile, and mounts `/tmp` as a tmpfs. The `dev-box-data` volume is mounted at `/var/lib/dev-box`; only the SSH host keys are kept there. The `dev-box-dnf5-cache` volume persists the DNF cache.

`codex-box` mounts the host home directory read-write, including projects, portable tools, shell and Git configuration, the chezmoi source repository, and `~/.codex`. The recursive bind is intentionally broad, but the host's rootless Podman storage and Zed server runtime directory are masked because they expose container state and live sockets rather than development files. The ordinary named volume `codex-box-ssh` overlays the host `~/.ssh` with a container-owned directory that does not contain private keys, while Fedora's systemd user SSH agent socket supplies authentication; forwarding the agent still authorizes Codex to use keys already loaded in that agent. Both container units trigger `ssh-agent-load.service` before startup. The container shares the host network namespace, so it can reach notebooks and other services started in `dev-box` through localhost without port mappings; listening ports are shared with the host and `dev-box`. It does not receive the host IPC namespace, devices, or the host user runtime directory apart from the explicitly forwarded SSH agent socket. The service uses `UserNS=keep-id` and `SecurityLabelDisable=true`.

`kimi-web-box` uses the same home, host network, SSH agent, and directory masks as `codex-box`, with its own `kimi-web-box-ssh` volume. Kimi configuration, credentials, and sessions reside in the shared `~/.kimi-code`. Update the host Kimi installation and restart `kimi-web-box.service` to update the agent without rebuilding the image.

All three containers mask the host's rootless Podman storage at `~/.local/share/containers`. The agent containers also mask `~/.local/share/zed/server_state`; `dev-box` keeps it accessible for Zed's remote server running inside that container.

All three containers use the host's hostname so hostname-dependent chezmoi templates render consistently. Applying systemd units and controlling the containers still belongs to the host: the containers do not receive the host user systemd bus.

Because the host `~/.codex` directory is shared, its configuration, hooks, skills, credentials, and app-server state are shared as well. `codex-box` must be the only app-server owner using that home at a time; do not start a second host or SSH app-server against the same `~/.codex`. The separate container remains useful as a process, package, device, namespace, and lifecycle boundary, but it is not a confidentiality boundary for the shared home.

### Updating Codex

Update the host installation reached through `~/.local/bin/codex`, then restart `codex-box.service`. No image rebuild is needed for a Codex update. Keep the running version's companion binaries and resources available until the service has restarted. Codex configuration, credentials, and runtime state remain in the shared `~/.codex` directory.

When migrating from the former Codex-specific image, applying the container sources removes `codex-box.build` and adds `box-base.build`. Reload the user units, build `box-base-build.service`, then restart `codex-box.service` as shown above.

### Kimi Web access

Kimi listens on `127.0.0.1:58627` with native authentication disabled. Codex and other host-network processes can call its API directly. Remote access belongs to Tailscale Serve and the tailnet access policy; anyone allowed to use the endpoint can submit tasks with access to the shared home. The allowed Host suffix comes from `tailscale.domain` in the chezmoi data. It is a DNS-rebinding check, not user authentication.

On the host, check the existing Serve configuration before assigning HTTPS port 58627. If that listener is already in use, choose a free HTTPS port rather than replacing it:

```sh
curl --fail http://127.0.0.1:58627/api/v1/healthz
tailscale serve status
sudo tailscale serve --bg --https=58627 http://127.0.0.1:58627
tailscale serve status
```

Open the HTTPS URL printed by Serve without a token. Restrict access to the host's TCP port 58627 to the intended users or devices in the tailnet policy. Serve's background configuration persists across reboots; do not enable Funnel for this endpoint. To remove only this listener, run `sudo tailscale serve --https=58627 off`.

Kimi may advance to the next port if 58627 is occupied. Check `journalctl --user -u kimi-web-box.service` after startup and resolve a port collision before relying on the proxy target. Verify both the browser UI and an API request through Serve after deployment; the localhost health probe alone does not validate the remote path.
