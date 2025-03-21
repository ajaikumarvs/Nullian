#!/bin/bash
set -e

# Configuration variables
DIST_NAME="NullOS"
DIST_VERSION="1.0"
OUTPUT_DIR="output"
BUILD_DIR="build"
ARCH="amd64"

# Print banner
echo "====================================="
echo "Building $DIST_NAME $DIST_VERSION"
echo "====================================="

# Create build and output directories
mkdir -p "$OUTPUT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy configuration to build directory
cp -r config "$BUILD_DIR/"

# Make hook scripts executable
chmod +x "$BUILD_DIR/config/hooks/live/"*.hook.chroot

# Prepare assets
echo "Preparing assets..."

# Create directory structure for wallpapers
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/$DIST_NAME"
# Copy wallpapers if they exist
if [ -d "assets/wallpapers" ] && [ "$(ls -A assets/wallpapers 2>/dev/null)" ]; then
  cp -r assets/wallpapers/* "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/$DIST_NAME/"
else
  echo "Note: No wallpapers found in assets/wallpapers"
fi

# Copy GNOME theme assets if they exist
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/themes"
if [ -d "assets/themes" ] && [ "$(ls -A assets/themes 2>/dev/null)" ]; then
  cp -r assets/themes/* "$BUILD_DIR/config/includes.chroot/usr/share/themes/"
else
  echo "Note: No theme files found in assets/themes"
fi

# Copy GRUB boot animation files if they exist
mkdir -p "$BUILD_DIR/config/includes.chroot/boot/grub/themes/$DIST_NAME"
if [ -d "assets/bootanimation" ] && [ "$(ls -A assets/bootanimation 2>/dev/null)" ]; then
  cp -r assets/bootanimation/* "$BUILD_DIR/config/includes.chroot/boot/grub/themes/$DIST_NAME/"
else
  echo "Note: No boot animation files found in assets/bootanimation"
fi

# Copy any custom scripts if they exist
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/local/bin"
if [ -d "assets/scripts" ] && [ "$(ls -A assets/scripts 2>/dev/null)" ]; then
  cp -r assets/scripts/* "$BUILD_DIR/config/includes.chroot/usr/local/bin/"
  chmod +x "$BUILD_DIR/config/includes.chroot/usr/local/bin/"*
else
  echo "Note: No scripts found in assets/scripts"
fi

# Set up GRUB config to use our theme
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/default"
cat > "$BUILD_DIR/config/includes.chroot/etc/default/grub" << EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo $DIST_NAME\`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_THEME="/boot/grub/themes/$DIST_NAME/theme.txt"
EOF

# Create default dconf settings for GNOME
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/dconf/db/local.d"
cat > "$BUILD_DIR/config/includes.chroot/etc/dconf/db/local.d/01-background" << EOF
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/$DIST_NAME/default.jpg'
picture-uri-dark='file:///usr/share/backgrounds/$DIST_NAME/default-dark.jpg'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/$DIST_NAME/lock.jpg'
EOF

# Create dconf profile
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/dconf/profile"
echo "user-db:user
system-db:local" > "$BUILD_DIR/config/includes.chroot/etc/dconf/profile/user"

# Navigate to build directory and start the build process
cd "$BUILD_DIR"

# Configure the live-build
lb config \
  --binary-images iso-hybrid \
  --mode debian \
  --architectures "$ARCH" \
  --distribution bookworm \
  --debian-installer live \
  --debian-installer-gui true \
  --archive-areas "main contrib non-free non-free-firmware" \
  --apt-indices true \
  --apt-recommends true \
  --bootappend-live "boot=live components locales=en_US.UTF-8" \
  --iso-application "$DIST_NAME" \
  --iso-publisher "Your Name" \
  --iso-volume "$DIST_NAME $DIST_VERSION"

# Build the ISO
lb build

# Move the resulting ISO to the output directory
if [ -f "live-image-$ARCH.hybrid.iso" ]; then
  mv "live-image-$ARCH.hybrid.iso" "../$OUTPUT_DIR/$DIST_NAME-$DIST_VERSION-$ARCH.iso"
  echo "Build completed successfully! ISO available at: $OUTPUT_DIR/$DIST_NAME-$DIST_VERSION-$ARCH.iso"
else
  echo "Build failed! No ISO was generated."
  exit 1
fi

cd ..