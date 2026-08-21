#!/bin/sh
# Deploy host-level configuration into /etc. Files in this tree mirror
# absolute paths on the host; /etc is not managed by chezmoi, so this
# script is the deployment mechanism. Self-elevates via sudo.
#
# Usage: host/install.sh [install|check|uninstall]

set -eu

case "${1:-install}" in
    install|check|uninstall) ;;
    *) echo "usage: $0 [install|check|uninstall]" >&2; exit 2 ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
    exec sudo "$self" "$@"
fi

cd "$(dirname "$0")"

# Files mirrored verbatim to the same absolute path; adding a file to
# this tree only requires listing it here.
files="etc/nftables/input-policy.nft"

# The entrypoint loaded by nftables.service. This script owns it: it is
# rewritten on every install (a .bak copy is kept) so that stale includes
# from earlier manual deploys cannot silently win. Permissions are set
# explicitly because sudo may inherit a restrictive umask.
nftables_conf=/etc/sysconfig/nftables.conf

case "${1:-install}" in
    install)
        for f in $files; do
            install -D -m 0644 "$f" "/$f"
        done
        # Superseded by input-policy.nft; remove the old file so a stale
        # include cannot reference it.
        rm -f /etc/nftables/ssh-access.nft
        if [ -f "$nftables_conf" ]; then
            cp -a "$nftables_conf" "$nftables_conf.bak"
        fi
        printf 'include "/etc/nftables/input-policy.nft"\n' > "$nftables_conf"
        chmod 644 "$nftables_conf"
        nft -c -f "$nftables_conf"
        systemctl enable nftables.service
        # restart (not start) so a previously loaded ruleset is flushed
        # before the new one is applied
        systemctl restart nftables.service
        nft list table inet host-access
        ;;
    check)
        nft -c -f etc/nftables/input-policy.nft
        echo "syntax ok"
        ;;
    uninstall)
        systemctl disable --now nftables.service
        rm -f "$nftables_conf" "$nftables_conf.bak" \
            /etc/nftables/input-policy.nft /etc/nftables/ssh-access.nft
        ;;
esac
