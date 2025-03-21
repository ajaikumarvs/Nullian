#!/bin/bash

set -e

# Configuration
DISTRO="bookworm"  # Change to your Debian version
ARCH="amd64"
MIRROR="http://deb.debian.org/debian"
CHROOT_DIR="$HOME/nullian-build"
ISO_OUTPUT="$HOME/nullian.iso"
ASSETS_DIR="$HOME/assets"  # Store wallpapers, themes, logos here

# Ensure required packages are installed
sudo apt update && sudo apt install -y debootstrap live-build squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin snapd

# Step 1: Create Debian Base System
echo "[+] Creating Debian base system..."
sudo debootstrap --arch=$ARCH $DISTRO $CHROOT_DIR $MIRROR

# Step 2: Configure the chroot environment
echo "[+] Configuring chroot..."
sudo cp /etc/resolv.conf $CHROOT_DIR/etc/
sudo mount --bind /dev $CHROOT_DIR/dev
sudo mount --bind /proc $CHROOT_DIR/proc
sudo mount --bind /sys $CHROOT_DIR/sys

# Step 3: Install Custom Packages
echo "[+] Installing packages inside chroot..."
sudo chroot $CHROOT_DIR /bin/bash -c "
    apt update && apt install -y \
    gnome-core gnome-shell gdm3 \
    libreoffice network-manager xorg sudo task-gnome-desktop tasksel \
    plymouth plymouth-themes grub2 grub-efi-amd64-bin \
    live-boot systemd-sysv
    
    snap install core
    snap install code-insiders --classic
"

# Step 4: Apply Branding
echo "[+] Applying branding..."
# Copy wallpapers
echo "[+] Copying wallpapers..."
sudo cp -r $ASSETS_DIR/wallpapers $CHROOT_DIR/usr/share/backgrounds/nullian

# Set GRUB theme
echo "[+] Setting GRUB theme..."
sudo mkdir -p $CHROOT_DIR/boot/grub/themes/nullian
sudo cp -r $ASSETS_DIR/grub-theme/* $CHROOT_DIR/boot/grub/themes/nullian
sudo chroot $CHROOT_DIR /bin/bash -c "echo 'GRUB_THEME=/boot/grub/themes/nullian/theme.txt' >> /etc/default/grub"

# Set Plymouth boot animation
echo "[+] Configuring Plymouth..."
sudo mkdir -p $CHROOT_DIR/usr/share/plymouth/themes/nullian
sudo cp -r $ASSETS_DIR/plymouth/* $CHROOT_DIR/usr/share/plymouth/themes/nullian

# Step 5: Prepare for ISO creation
echo "[+] Setting up live-build..."
sudo chroot $CHROOT_DIR /bin/bash -c "
    mkdir -p /etc/live/config
    echo 'live-config live-config.user-default-groups sudo,netdev' > /etc/live/config/00-config
    update-initramfs -u
"

# Step 6: Build the ISO
echo "[+] Building the ISO..."
cd $HOME
mkdir -p iso/{live,isolinux}
sudo mksquashfs $CHROOT_DIR iso/live/filesystem.squashfs -comp xz -Xbcj x86

# Create bootloader config
cat <<EOF | sudo tee iso/isolinux/isolinux.cfg
UI menu.c32
PROMPT 0
TIMEOUT 50
DEFAULT live

LABEL live
  MENU LABEL Start Nullian
  KERNEL /live/vmlinuz
  APPEND boot=live config quiet splash initrd=/live/initrd.img
EOF

sudo grub-mkrescue -o $ISO_OUTPUT iso --modules="iso9660"

echo "[+] Nullian ISO built at: $ISO_OUTPUT"
