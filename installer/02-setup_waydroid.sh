#!/bin/bash -eu

CYAN='\e[1;36m'
RESET='\e[0m'

# Set repository URL for downloading additional resources.
REPO_URL='https://github.com/neilgfoster/cros-waydroid-installer/raw/refs/heads/main'

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

# Mount binderfs and create loopback devices
echo_info '[+] Mounting Binder filesystem and creating loopback devices...'
sudo mkdir -p /dev/binderfs
sudo mount -t binder binder /dev/binderfs
sudo mknod /dev/loop-control c 10 237

for ((i=0; i<=15; i++)); do
  sudo rm -f /dev/loop$i
  sudo mknod /dev/loop$i b 7 $i
done

# Install Waydroid
echo_info '[+] Installing Waydroid...'
sudo apt install curl ca-certificates -y
curl -s https://repo.waydro.id | sudo bash
sudo ln -s true /bin/modprobe || true
sudo apt install waydroid unzip -y

cat <<EOT

Select an Android version to install:

  1) Default [VANILLA]
  2) Default [GAPPS]
  3) LineageOS 17.1 [Android 10] [VANILLA] [2022-07-23]
  4) LineageOS 17.1 [Android 10] [GAPPS]   [2022-07-23]
  5) LineageOS 18.1 [Android 11] [VANILLA] [2025-06-28]
  6) LineageOS 18.1 [Android 11] [GAPPS]   [2025-06-28]
  7) LineageOS 20.0 [Android 13] [VANILLA] [2025-08-23]
  8) LineageOS 20.0 [Android 13] [GAPPS]   [2025-08-09]

EOT
read -p 'Select an option [1-8]: ' ANDROID_VERSION
while [[ ! "${ANDROID_VERSION}" =~ ^[1-8]$ ]]; do
  echo_error 'Invalid input! Please try again.'
  read -p 'Select an option [1-8]: ' ANDROID_VERSION
done

echo_info "[+] Installing Waydroid...${RESET}"
case "${ANDROID_VERSION}" in
1)
  sudo waydroid init -s VANILLA
;;
2)
  sudo waydroid init -s GAPPS
;;
[3-8])
    # Map option to image download url
    case "${ANDROID_VERSION}" in
      3) 
        VENDOR_IMAGE="lineage-17.1-20220723-MAINLINE-waydroid_x86_64-vendor.zip"
        SYSTEM_IMAGE="lineage-17.1-20220723-VANILLA-waydroid_x86_64-system.zip"
        ;;
      4)
        VENDOR_IMAGE="lineage-17.1-20220723-MAINLINE-waydroid_x86_64-vendor.zip"
        SYSTEM_IMAGE="lineage-17.1-20220723-GAPPS-waydroid_x86_64-system.zip"
        ;;
      5)
        VENDOR_IMAGE="lineage-18.1-20250628-MAINLINE-waydroid_x86_64-vendor.zip"
        SYSTEM_IMAGE="lineage-18.1-20250628-VANILLA-waydroid_x86_64-system.zip"
        ;;
      6)
        VENDOR_IMAGE="lineage-18.1-20250628-MAINLINE-waydroid_x86_64-vendor.zip"
        SYSTEM_IMAGE="lineage-18.1-20250628-GAPPS-waydroid_x86_64-system.zip"
        ;;
      7)
        VENDOR_IMAGE="lineage-20.0-20250809-MAINLINE-waydroid_x86_64-vendor.zip"
        SYSTEM_IMAGE="lineage-20.0-20250823-VANILLA-waydroid_x86_64-system.zip"
        ;;
      8)
        VENDOR_IMAGE="lineage-20.0-20250809-MAINLINE-waydroid_x86_64-vendor.zip"
        SYSTEM_IMAGE="lineage-20.0-20250809-GAPPS-waydroid_x86_64-system.zip"
        ;;
    esac
    VENDOR_IMAGE_URL="https://sourceforge.net/projects/waydroid/files/images/vendor/waydroid_x86_64/${VENDOR_IMAGE}"
    SYSTEM_IMAGE_URL="https://sourceforge.net/projects/waydroid/files/images/system/lineage/waydroid_x86_64/${SYSTEM_IMAGE}"

    # Create and clean image directory
    sudo mkdir -p /etc/waydroid-extra/images
    cd /etc/waydroid-extra/images
    sudo rm -rf *

    # Download and extract vendor image
    echo_info "[+] Downloading vendor image..."
    sudo curl -L "${VENDOR_IMAGE_URL}" -o "${VENDOR_IMAGE}"
    sudo unzip ${VENDOR_IMAGE}
    sudo rm -f ${VENDOR_IMAGE}

    # Download and extract system image
    echo_info "[+] Downloading system image..."
    sudo curl -L "${SYSTEM_IMAGE_URL}" -o "${SYSTEM_IMAGE}"
    sudo unzip ${SYSTEM_IMAGE}
    sudo rm -f ${SYSTEM_IMAGE}

    # Initialize Waydroid with downloaded images
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
sudo curl -L "${REPO_URL}/scripts/stop-waydroid" -o /usr/bin/stop-waydroid
sudo chmod +x /usr/bin/stop-waydroid

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
