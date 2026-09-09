# Samba container

Native Samba on Fedora 44, built and run by a rootless, user-level Podman Quadlet. A single `public` share exposes `/srv/public` on TCP 445 inside a private container network. A host-side Quadlet drop-in publishes it on the host's Tailscale IPv4 address at TCP 1445. Samba's configuration contains no host interface names or addresses. Quadlet mounts the host's `~/Documents` read-write beneath the share as `Documents`; additional directories can be mounted beneath the same share. The name `public` does not enable guest access: authentication is required.

## Files and ownership

- `Containerfile` installs Fedora's Samba packages and creates a fixed `smb` account (UID 1000) in `smbusers` (GID 1000). It prepares `/srv/public` and Samba's state/cache directories, checks the configuration with `testparm`, and starts foreground `smbd` directly through `CMD`.
- `rootfs/etc/samba/smb.conf` is the complete, native Samba configuration. It is copied into the image without configuration generation or environment-variable substitution. No startup wrapper is needed; Samba creates its runtime lock and PID directories beneath the `/run/samba` tmpfs mount.
- `../../home/dot_config/containers/systemd/smb-box.build` and `smb-box.container` own image construction, mounts, networking, and service lifecycle. Like dev-box, these bindings are managed only on `loongcc-workstation`.
- `../../home/dot_config/containers/systemd/smb-box.container.d/10-network.conf.tmpl` reads the machine-local `tailscale.ipv4` value and publishes `<configured-ip>:1445:445`. The address is entered during chezmoi initialization and saved in `~/.config/chezmoi/chezmoi.toml`. Missing or empty values leave the port unpublished; non-empty values must be valid Tailscale IPv4 addresses in `100.64.0.0/10`.
- The `smb-box-data` named volume persists `/var/lib/samba`, including the server identity and password database. Configuration stays in the image; runtime locks and caches are disposable.

`UserNS=keep-id:uid=1000,gid=1000` maps the host user's UID/GID to the fixed SMB account inside the container. The image is independent of the host username and numeric IDs. `User=0` starts Samba as root **inside that user namespace** so it can switch to the authenticated `smb` account; Podman itself runs as the ordinary host user. Filesystem access as `smb` is therefore constrained by that host user's permissions. Mac clients always log in as `smb`.

SELinux container separation is disabled for this container, as in dev-box, because the mounted host directories are also used by other applications. Initially, only `~/Documents` is mounted for sharing. Do not add `:U`, `:z`, or `:Z` to these mounts: they recursively change host ownership or labels. SELinux is not disabled globally.

## Shared folders

`smb.conf` always exports `/srv/public` as `[public]`. This parent directory belongs to the container; it does not require a corresponding `~/public` folder on the host. The current Quadlet mounts:

```ini
Volume=%h/Documents:/srv/public/Documents:rw
```

To also share `~/Pictures` read-only, add this line to `smb-box.container` after making sure the host directory exists (use `:rw` instead to allow writes):

```ini
Volume=%h/Pictures:/srv/public/Pictures:ro
```

Mac clients then see `Documents` and `Pictures` inside the same `public` share. Each host directory gets a distinct destination beneath `/srv/public`; remove its `Volume=` line to stop sharing it. Adding or removing these mounts requires only applying the changed Quadlet and recreating the container, with no Samba configuration change or image rebuild:

```sh
chezmoi cat ~/.config/containers/systemd/smb-box.container
chezmoi diff
chezmoi apply ~/.config/containers/systemd/smb-box.container
systemctl --user daemon-reload
systemctl --user restart smb-box.service
```

## First start

Run these commands on the Fedora host, as the user who owns `~/Documents`. Podman, user namespaces, and host Tailscale must already be working. Get the host's Tailscale IPv4 address and check that TCP 1445 is unused:

```sh
tailscale ip -4
ss -ltn 'sport = :1445'
```

Enter that IPv4 address in the `Tailscale IPv4 address` prompt during chezmoi initialization. For an existing configuration, use `chezmoi edit-config` and add `ipv4 = "<your Tailscale IPv4>"` to its existing `[data.tailscale]` table, or run `chezmoi init --prompt` to fill the new prompt. The default is empty, which leaves SMB unpublished.

Chezmoi generates `~/.config/containers/systemd/smb-box.container.d/10-network.conf` from this saved value; rendering does not execute Tailscale. If the address changes, update `tailscale.ipv4`, re-apply the drop-in, reload the user manager, and restart the container.

The Tailscale address must be available when Podman starts; after Tailscale is ready, restart `smb-box.service` if it previously failed to bind. No Tailscale Serve rule or low-port sysctl change is needed. Host loopback has no published port; local Samba diagnostics below run inside the container.

Review and apply the three managed files. This repository uses chezmoi's symlink mode, so `chezmoi cat` displays source link paths for the two non-template files and rendered content for the drop-in:

```sh
chezmoi cat ~/.config/containers/systemd/smb-box.build ~/.config/containers/systemd/smb-box.container ~/.config/containers/systemd/smb-box.container.d/10-network.conf
chezmoi diff
chezmoi apply ~/.config/containers/systemd/smb-box.build ~/.config/containers/systemd/smb-box.container ~/.config/containers/systemd/smb-box.container.d/10-network.conf
systemctl --user daemon-reload
systemctl --user start smb-box.service
```

The service builds its image through `smb-box-build.service`. Inspect startup before creating the SMB password:

```sh
systemctl --user status smb-box-build.service smb-box.service
journalctl --user -u smb-box.service -n 80 --no-pager
podman exec --user 0 -it my-smb-box smbpasswd -a smb
```

There is no guest access or default password. Before `smbpasswd -a`, the Unix account exists but cannot log in over SMB. The password is stored in the named volume, not in Git or the image. To change it later:

```sh
podman exec --user 0 -it my-smb-box smbpasswd smb
```

`WantedBy=default.target` starts the generated service with the user manager; Quadlet handles enablement when the manager reloads. For startup at boot without an interactive login, the host user also needs lingering. Check `loginctl show-user "$USER" -p Linger`; if needed, enable it on the host with `sudo loginctl enable-linger "$USER"`.

## Connect and verify

In macOS Finder, press Command-K and enter `smb://<host-tailscale-name>:1445/public`, then open `Documents` inside it. Authenticate as `smb` with the SMB password created above. Tailscale policy and any host firewall must allow this Mac to reach TCP 1445 on the host's Tailscale address.

On the host, check Samba's configuration, Podman's published endpoint, and the host listener:

```sh
podman exec my-smb-box testparm --suppress-prompt
podman port my-smb-box 445/tcp
ss -ltn 'sport = :1445'
podman exec -it my-smb-box smbclient //127.0.0.1/public -p 445 -U smb -c 'ls; cd Documents; ls'
```

The published endpoint should be exactly the configured Tailscale IPv4 address at port 1445, never `0.0.0.0:1445`, `[::]:1445`, or a LAN address. Check that connecting to the host's LAN address on port 1445 fails. A successful `smbclient` check inside the container does not verify external access: also connect from the Mac, check directory listing and opening a PDF, and create, modify, and remove a disposable test file inside `public/Documents`. Before removing it, check on the host that the file belongs to the host user. Then restart `smb-box.service` and reconnect to verify that the credentials survive. For remotely rebuilt PDFs, also test whether the chosen viewer notices updates.

## Change configuration and update

Edit `rootfs/etc/samba/smb.conf` directly. Configuration changes are baked into the image, so rebuild and restart:

```sh
systemctl --user restart smb-box-build.service
systemctl --user restart smb-box.service
```

The second command should only be run if the build succeeds. Existing SMB connections are interrupted by the restart. For Quadlet edits, first apply the affected managed bindings with chezmoi and run `systemctl --user daemon-reload`. Published-port changes belong in the network drop-in template. To change the host IP, edit `tailscale.ipv4` in the local chezmoi configuration, re-apply `~/.config/containers/systemd/smb-box.container.d/10-network.conf`, reload the user manager, and restart the container without rebuilding the image. Do not edit the generated drop-in directly.

The `public` share permits writes with `read only = no`; the Documents mount uses `:rw`. Clients can create, modify, and delete files within Documents subject to the host user's filesystem permissions. The root-owned `/srv/public` parent remains non-writable by the SMB account; clients manage files within the mounted directories. To make an individual directory read-only, use `:ro` on its mount, apply the changed Quadlet, reload the user manager, and restart. To make the entire share read-only, set `read only = yes` and rebuild the image before restarting.

To fetch current packages even when build layers are cached, rebuild explicitly without the cache, then restart only if that succeeds:

```sh
podman build --pull=always --no-cache \
  -t localhost/fedora-smb-box \
  ~/.local/share/chezmoi/boxes/smb-box
```

The Fedora major version is selected in `Containerfile`; changing it is an explicit image update. Recheck the effective configuration, login, file access, and listener addresses after updates. Back up the stopped container's named volume before major Samba upgrades; downgrading the image does not roll back its databases.

The Mac compatibility modules are `fruit` and `streams_xattr`. Finder metadata uses extended attributes, while resource forks use `._` AppleDouble files to avoid filesystem xattr size limits. Those files are part of Mac metadata and should not be blindly removed.

To stop sharing, run `systemctl --user stop smb-box.service`. To retire it across boots, remove the managed Quadlet bindings and reload the user manager. Preserve the named volume if you want to retain the server identity and credentials.

## References

- [Samba configuration reference](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html)
- [Samba macOS compatibility module](https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html)
- [Podman user namespaces](https://docs.podman.io/en/latest/markdown/podman-run.1.html#userns-mode)
- [Quadlet reference](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
