# Development containers

This repository provides two Fedora-based containers for different kinds of development work. `dev-box` is the general-purpose environment, with an SSH service and access to the host development context. `codex-box` runs Codex Remote Control as an independent service while sharing the host user's development files and Codex state. Keeping these roles in separate containers gives the interactive development environment and the Codex service different process and system-access boundaries.

## Use the containers

After changing the container sources or their chezmoi data, render the managed systemd files and reload the user units:

```sh
chezmoi apply ~/.config/containers/systemd
systemctl --user daemon-reload
```

Build and restart each container independently when it is needed:

```sh
systemctl --user restart dev-box-build.service
systemctl --user restart dev-box.service

systemctl --user restart codex-box-build.service
systemctl --user restart codex-box.service
```

The build service updates the image; it does not replace an already-running container. Restart the corresponding container service after its build completes.

## Architecture

### Images and processes

`dev-box/Containerfile` builds a shared `box-base` stage from `registry.fedoraproject.org/fedora:latest`. The base installs the common command-line and build tools and creates the configured user. The `dev-box` target adds `openssh-server` and starts `/usr/local/sbin/dev-box-run`. That entrypoint prepares the persistent SSH host keys, validates `sshd`, and replaces itself with `sshd -D -e`, so `sshd` is the container's long-running process.

The `codex-box` target reuses the base stage and installs a pinned Codex release under `/opt/codex`, exposing it as `/usr/local/bin/codex`. It uses the configured user's home as its working directory and runs `codex app-server --remote-control --listen unix://` as that user. Both Quadlet containers use `RunInit=true` and restart after failure with a five-second delay.

### Storage and access boundaries

`dev-box` uses the host network and IPC namespaces; its `sshd` listens on port 2222 in the shared host network namespace. It mounts the host home directory at `/home/<user>`, while the ordinary named volume `dev-box-ssh` overlays the host `~/.ssh`, the host `authorized_keys` remains available read-only for inbound login, and outbound SSH authentication uses the host agent socket. It receives `/dev/kfd` and `/dev/dri`, uses an unconfined seccomp profile, and mounts `/tmp` as a tmpfs. The `dev-box-data` volume is mounted at `/var/lib/dev-box`; only the SSH host keys are kept there. The `dev-box-dnf5-cache` volume persists the DNF cache.

`codex-box` mounts the host home directory read-write, including projects, portable tools, shell and Git configuration, the chezmoi source repository, and `~/.codex`. The ordinary named volume `codex-box-ssh` overlays the host `~/.ssh` with a container-owned directory that does not contain private keys, while Fedora's systemd user SSH agent socket supplies authentication. Both container units trigger `ssh-agent-load.service`, which loads the passphrase-free Git key before the container starts. The container does not receive the host network, IPC namespace, devices, or runtime control sockets. The service uses `UserNS=keep-id` and `SecurityLabelDisable=true`.

### Updating Codex

The Codex repository, tag, Linux x86_64 asset, and SHA-256 digest are declared together in `home/.chezmoidata/container-pkgs.yaml`. To update Codex, change that release metadata as a set, run `chezmoi apply ~/.config/containers/systemd`, reload the user units, then rebuild and restart `codex-box`. The build verifies the downloaded archive against the declared digest before installing it. Codex state remains in the shared host home directory across image updates.
