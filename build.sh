#!/bin/bash
set -e

# Configuration variables (customizable)
DIST_NAME="NullOS"
DIST_VERSION="1.0"
OUTPUT_DIR="output"
BUILD_DIR="build"
ARCH="amd64"
MIRROR="http://deb.debian.org/debian"
LOCALE="en_US.UTF-8"
BUILD_LOG="build.log"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script requires root privileges. Run with sudo."
    exit 1
fi

# Check for required tools
echo "Checking dependencies..."
for tool in live-build debootstrap xorriso; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed. Install it with 'apt install $tool'."
        exit 1
    fi
done

# Print banner
echo "====================================="
echo "Building $DIST_NAME $DIST_VERSION"
echo "=====================================" | tee -a "$BUILD_LOG"

# Create build and output directories
mkdir -p "$OUTPUT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy configuration to build directory
cp -r config "$BUILD_DIR/"

# Make hook scripts executable
chmod +x "$BUILD_DIR/config/hooks/live/"*.hook.chroot 2>/dev/null || echo "No hook scripts found."

# Prepare assets
echo "Preparing assets..." | tee -a "$BUILD_LOG"

# Wallpapers
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/$DIST_NAME"
if [ -d "assets/wallpapers" ] && [ "$(ls -A assets/wallpapers)" ]; then
    cp -r assets/wallpapers/* "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/$DIST_NAME/"
    echo "Wallpapers copied." | tee -a "$BUILD_LOG"
else
    echo "Note: No wallpapers found in assets/wallpapers" | tee -a "$BUILD_LOG"
fi

# GNOME themes
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/themes"
if [ -d "assets/themes" ] && [ "$(ls -A assets/themes)" ]; then
    cp -r assets/themes/* "$BUILD_DIR/config/includes.chroot/usr/share/themes/"
    echo "Themes copied." | tee -a "$BUILD_LOG"
else
    echo "Note: No theme files found in assets/themes" | tee -a "$BUILD_LOG"
fi

# GRUB boot animation
mkdir -p "$BUILD_DIR/config/includes.chroot/boot/grub/themes/$DIST_NAME"
if [ -d "assets/bootanimation" ] && [ "$(ls -A assets/bootanimation)" ]; then
    cp -r assets/bootanimation/* "$BUILD_DIR/config/includes.chroot/boot/grub/themes/$DIST_NAME/"
    echo "Boot animation copied." | tee -a "$BUILD_LOG"
else
    echo "Note: No boot animation files found in assets/bootanimation" | tee -a "$BUILD_LOG"
fi

# Custom scripts
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/local/bin"
if [ -d "assets/scripts" ] && [ "$(ls -A assets/scripts)" ]; then
    cp -r assets/scripts/* "$BUILD_DIR/config/includes.chroot/usr/local/bin/"
    chmod +x "$BUILD_DIR/config/includes.chroot/usr/local/bin/"*
    echo "Scripts copied and made executable." | tee -a "$BUILD_LOG"
else
    echo "Note: No scripts found in assets/scripts" | tee -a "$BUILD_LOG"
fi

# GRUB config
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/default"
cat > "$BUILD_DIR/config/includes.chroot/etc/default/grub" << EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo $DIST_NAME\`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_THEME="/boot/grub/themes/$DIST_NAME/theme.txt"
EOF

# Dconf settings for GNOME
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/dconf/db/local.d"
cat > "$BUILD_DIR/config/includes.chroot/etc/dconf/db/local.d/01-background" << EOF
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/$DIST_NAME/default.jpg'
picture-uri-dark='file:///usr/share/backgrounds/$DIST_NAME/default-dark.jpg'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/$DIST_NAME/lock.jpg'
EOF

mkdir -p "$BUILD_DIR/config/includes.chroot/etc/dconf/profile"
echo "user-db:user
system-db:local" > "$BUILD_DIR/config/includes.chroot/etc/dconf/profile/user"

# Navigate to build directory
cd "$BUILD_DIR"

# Configure live-build
echo "Configuring live-build..." | tee -a "../$BUILD_LOG"
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
    --bootappend-live "boot=live components locales=$LOCALE" \
    --iso-application "$DIST_NAME" \
    --iso-publisher "Your Name" \
    --iso-volume "$DIST_NAME $DIST_VERSION" \
    --mirror-bootstrap "$MIRROR" \
    --mirror-chroot "$MIRROR" \
    --mirror-binary "$MIRROR" \
    --security true 2>&1 | tee -a "../$BUILD_LOG"

# Build the ISO
echo "Building ISO (this may take a while)..." | tee -a "../$BUILD_LOG"
lb build 2>&1 | tee -a "../$BUILD_LOG"

# Move the ISO
if [ -f "live-image-$ARCH.hybrid.iso" ]; then
    mv "live-image-$ARCH.hybrid.iso" "../$OUTPUT_DIR/$DIST_NAME-$DIST_VERSION-$ARCH.iso"
    echo "Build completed successfully! ISO available at: $OUTPUT_DIR/$DIST_NAME-$DIST_VERSION-$ARCH.iso" | tee -a "../$BUILD_LOG"
else
    echo "Build failed! Check $BUILD_LOG for details." | tee -a "../$BUILD_LOG"
    exit 1
fi

cd ..

# Optional cleanup (uncomment if desired)
# echo "Cleaning up build directory..." | tee -a "$BUILD_LOG"
# rm -rf "$BUILD_DIR"