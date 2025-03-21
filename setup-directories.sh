#!/bin/bash

# Create all required asset directories
echo "Creating asset directories..."
mkdir -p assets/wallpapers
mkdir -p assets/themes
mkdir -p assets/bootanimation
mkdir -p assets/scripts

# Create all required config directories
echo "Creating config directories..."
mkdir -p config/hooks/live
mkdir -p config/package-lists
mkdir -p config/includes.chroot/etc/skel
mkdir -p config/bootloaders/isolinux

echo "Directory structure set up successfully!"