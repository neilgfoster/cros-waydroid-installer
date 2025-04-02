#!/bin/bash -eu

CYAN='\e[1;36m'
RESET='\e[0m'

REPO_URL='https://github.com/supechicken/ChromeOS-Waydroid-Installer/raw/refs/heads/main'

ANDROID13_IMG=(
  https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer/releases/download/Android13/lineage-20-20250121-UNOFFICIAL-10MinuteSteamDeckGamer-Waydroid.zip
  833be8279a605285cc2b9c85425511a100320102c7ff8897f254fcfdf3929bb1
)

ANDROID13_TV_IMG=(
  https://github.com/supechicken/waydroid-androidtv-build/releases/download/20250327/lineage-20.0-20250327-UNOFFICIAL-WaydroidATV_x86_64.zip
  44d77c229f4737dfca6e360cdc06a6a2860717b504038b11b0216ed8a51f6a5a
)

# Simplify colors and print errors to stderr (2).
echo_error() { echo -e "\e[1;91m${*}${RESET}" >&2; } # Use Light Red for errors.
echo_info() { echo -e "\e[1;33m${*}${RESET}" >&1; } # Use Yellow for informational messages.
echo_success() { echo -e "\e[1;32m${*}${RESET}" >&1; } # Use Green for success messages.
echo_intra() { echo -e "\e[1;34m${*}${RESET}" >&1; } # Use Blue for intrafunction messages.
echo_out() { echo -e "\e[0;37m${*}${RESET}" >&1; } # Use Gray for program output.

cat <<EOF
==============================================================================
Waydroid installer for Crostini - Stage 2

By SupeChicken666 - https://github.com/supechicken/ChromeOS-Waydroid-Installer
==============================================================================

EOF

# check if we are running in the Termina VM
if [ -f /etc/profile.d/PS1-termina.sh ]; then
  echo_error 'Please run this script inside Crostini!'
  exit 1
fi

echo_info '[+] Mounting Binder filesystem and creating loopback devices...'
sudo mkdir -p /dev/binderfs
sudo mount -t binder binder /dev/binderfs
sudo mknod /dev/loop-control c 10 237

for ((i=0; i<=15; i++)); do
  sudo rm -f /dev/loop$i
  sudo mknod /dev/loop$i b 7 $i
done

echo_info '[+] Installing Waydroid...'
sudo apt install curl ca-certificates -y
curl -s https://repo.waydro.id | sudo bash
sudo ln -s true /bin/modprobe || true
sudo apt install waydroid unzip -y

cat <<EOT

Select an Android version to install:

  1. Android 11    (official image)
  2. Android 13    (unofficial image by 10MinuteSteamDeckGamer)
  3. Android 13 TV (unofficial image)

EOT

read -p 'Select an option [1-3]: ' ANDROID_VERSION

while [[ "${ANDROID_VERSION}" != '1' && ${ANDROID_VERSION} != '2' && ${ANDROID_VERSION} != '3' ]]; do
  echo_error 'Invalid input! Please try again.'
  read -p 'Select an option [1-3]: ' ANDROID_VERSION
done

case "${ANDROID_VERSION}" in
1)
  echo_info "[+] Installing ${CYAN}Android 11${RESET}"
  sudo waydroid init -s VANILLA
;;
2|3)
  if [[ ${ANDROID_VERSION} == '2' ]]; then
    ANDROID_VERSION='Android 13'
    ANDROID_IMG_URL="${ANDROID13_IMG[0]}"
    ANDROID_IMG_SHA="${ANDROID13_IMG[1]}"
  else
    ANDROID_VERSION='Android 13 TV'
    ANDROID_IMG_URL="${ANDROID13_TV_IMG[0]}"
    ANDROID_IMG_SHA="${ANDROID13_TV_IMG[1]}"
  fi

  echo_info "[+] Installing ${CYAN}${ANDROID_VERSION}${RESET}"

  sudo mkdir -p /etc/waydroid-extra/images
  cd /etc/waydroid-extra/images

  if [ ! -f android13.zip ]; then
    echo_info '[+] Downloading Android 13 image...'
    sudo curl -L "${ANDROID_IMG_URL}" -o android13.zip
  fi

  echo_info '[+] Verifying archive...'
  sha256sum -c - <<< "${ANDROID_IMG_SHA} android13.zip"

  echo_info '[+] Decompressing Android 13 image...'
  sudo unzip android13.zip
  sudo rm android13.zip

  echo_info '[+] Initializing system...'
  sudo waydroid init -f
;;
esac

echo_info '[+] Setting up Cage...'
sudo apt install build-essential libx11-dev x11-utils cage xwayland -y
curl -L "${REPO_URL}/tools/cage-fullscreen.c" -o /tmp/cage-fullscreen.c
sudo gcc -O3 /tmp/cage-fullscreen.c -lX11 -o /usr/bin/cage-fullscreen

echo_info '[+] Installing scripts...'
sudo curl -L "${REPO_URL}/scripts/start-waydroid" -o /usr/bin/start-waydroid
sudo chmod +x /usr/bin/start-waydroid

echo_success '[+] Installation completed!'
echo_intra "
[Note]

In order to make Waydroid work properly, you will need to boot the custom kernel
manually each time when ChromeOS restarts:

  vmc start termina --enable-gpu --kernel /home/chronos/user/<PATH TO KERNEL>

If you wish doing that automatically for each startup, check https://github.com/supechicken/ChromeOS-AutoStart
If you need Google Apps/ARM compatibility layer, check https://github.com/casualsnek/waydroid_script

**DO NOT** start Waydroid apps directly through ChromeOS launcher. Instead, start Waydroid with:

  start-waydroid

---
Enjoy your Android installation!
"

# cleanup
sudo rm -rf /02-setup_waydroid.sh
