#!/usr/bin/env bash
set -euo pipefail
# Configuration and host keys live in this container's /etc/ssh.
mkdir -p /run/sshd
/usr/sbin/sshd -t -f /etc/ssh/sshd_config_fuselink
if [[ -f /run/sshd-fuselink.pid ]] && kill -0 "$(cat /run/sshd-fuselink.pid)" 2>/dev/null; then
  echo 'Container SSH already running (see /etc/ssh/sshd_config_fuselink)'
else
  /usr/sbin/sshd -f /etc/ssh/sshd_config_fuselink -E /var/log/sshd-fuselink.log
fi
