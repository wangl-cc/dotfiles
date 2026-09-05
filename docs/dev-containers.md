# Development containers

This repository provides two Fedora-based containers for different kinds of development work. `dev-box` is the general-purpose environment, with an SSH service and access to the host development context. `codex-box` runs Codex Remote Control as an independent service while sharing the host user's development files and Codex state. Keeping these roles in separate containers gives the interactive development environment and the Codex service different process and system-access boundaries.

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
```

The build service updates the image; it does not replace an already-running container. Restart the corresponding container service after its build completes. Both build services are capped at 15 minutes.

## Architecture

### Images and processes

`dev-box/Containerfile` builds a shared `box-base` stage from `registry.fedoraproject.org/fedora:latest`. The base installs the common command-line and build tools, creates the configured user, and provides `/var/home` as a compatibility link to `/home` for absolute paths created on Fedora Atomic hosts. The `dev-box` target adds `openssh-server` and starts `/usr/local/sbin/dev-box-run`. That entrypoint prepares the persistent SSH host keys, validates `sshd`, and replaces itself with `sshd -D -e`, so `sshd` is the container's long-running process.

`codex-box` uses the `box-base` image directly; there is no Codex-specific image stage. Its Quadlet unit selects the configured user and home working directory, then runs `/home/<user>/.local/bin/codex app-server --remote-control --listen unix://` from the shared home. The host must provide a working Linux Codex installation, including its companion binaries and resources, at that entry point. Both Quadlet containers use `RunInit=true` and restart after failure with a five-second delay.

### Storage and access boundaries

`dev-box` uses the host network and IPC namespaces; its `sshd` listens on port 2222 in the shared host network namespace. It mounts the host home directory at `/home/<user>`, while the ordinary named volume `dev-box-ssh` overlays the host `~/.ssh`, the host `authorized_keys` remains available read-only for inbound login, and outbound SSH authentication uses the host agent socket. It receives `/dev/kfd` and `/dev/dri`, uses an unconfined seccomp profile, and mounts `/tmp` as a tmpfs. The `dev-box-data` volume is mounted at `/var/lib/dev-box`; only the SSH host keys are kept there. The `dev-box-dnf5-cache` volume persists the DNF cache.

`codex-box` mounts the host home directory read-write, including projects, portable tools, shell and Git configuration, the chezmoi source repository, and `~/.codex`. The recursive bind is intentionally broad, but the host's rootless Podman storage and Zed server runtime directory are masked because they expose container state and live sockets rather than development files. The ordinary named volume `codex-box-ssh` overlays the host `~/.ssh` with a container-owned directory that does not contain private keys, while Fedora's systemd user SSH agent socket supplies authentication; forwarding the agent still authorizes Codex to use keys already loaded in that agent. Both container units trigger `ssh-agent-load.service` before startup. The container does not receive the host network or IPC namespace, devices, or the host user runtime directory apart from the explicitly forwarded SSH agent socket. The service uses `UserNS=keep-id` and `SecurityLabelDisable=true`.

Both containers use the host's hostname so hostname-dependent chezmoi templates render consistently. Applying systemd units and controlling the containers still belongs to the host: the containers do not receive the host user systemd bus.

Because the host `~/.codex` directory is shared, its configuration, hooks, skills, credentials, and app-server state are shared as well. `codex-box` must be the only app-server owner using that home at a time; do not start a second host or SSH app-server against the same `~/.codex`. The separate container remains useful as a process, package, device, namespace, and lifecycle boundary, but it is not a confidentiality boundary for the shared home.

### Updating Codex

Update the host installation reached through `~/.local/bin/codex`, then restart `codex-box.service`. No image rebuild is needed for a Codex update. Keep the running version's companion binaries and resources available until the service has restarted. Codex configuration, credentials, and runtime state remain in the shared `~/.codex` directory.

When migrating from the former Codex-specific image, applying the container sources removes `codex-box.build` and adds `box-base.build`. Reload the user units, build `box-base-build.service`, then restart `codex-box.service` as shown above.
