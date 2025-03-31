#!/bin/bash -eu

RESET='\e[0m'

# Simplify colors and print errors to stderr (2).
echo_error() { echo -e "\e[1;91m${*}${RESET}" >&2; } # Use Light Red for errors.
echo_info() { echo -e "\e[1;33m${*}${RESET}" >&1; } # Use Yellow for informational messages.
echo_success() { echo -e "\e[1;32m${*}${RESET}" >&1; } # Use Green for success messages.
echo_intra() { echo -e "\e[1;34m${*}${RESET}" >&1; } # Use Blue for intrafunction messages.
echo_out() { echo -e "\e[0;37m${*}${RESET}" >&1; } # Use Gray for program output.

cat <<EOF

============
Waydroid installer for Crostini - Stage 1

By SupeChicken666 - https://github.com/supechicken/ChromeOS-Waydroid-Installer
============

EOF

# check if we are running in the Termina VM
if [ ! -f /etc/profile.d/PS1-termina.sh ]; then
  echo_error 'Please run this script inside the Termina VM!'
  exit 1
fi

# check if we are running on custom kernel with binder support
if ! zgrep -q 'CONFIG_ANDROID_BINDERFS=y' /proc/config.gz; then
  echo_error 'Please boot Termina VM with custom kernel!'
  exit 1
fi

echo '[+] Setting up character/block device permission for the container...'
lxc config set penguin security.privileged true
lxc config set penguin raw.lxc - <<EOF
  lxc.cgroup.devices.allow = c 241:* rwm
  lxc.cgroup.devices.allow = c 10:237 rwm
  lxc.cgroup.devices.allow = b 7:* rwm
EOF

# restart container to apply changes
echo '[+] Restarting container to apply changes...'
lxc stop penguin
lxc start penguin

# download and start stage 2
echo '[+] Downloading script for next stage...'
curl -L https://github.com/supechicken/ChromeOS-Waydroid-Installer | lxc exec penguin -- bash -eu
