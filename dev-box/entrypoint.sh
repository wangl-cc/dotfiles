#!/bin/bash
set -e

if [ ! -f "/etc/ssh/ssh_host_ed25519_key" ]; then
    echo ">>> SSH host keys not found, generating new ones..."
    ssh-keygen -A
fi

exec "$@"
