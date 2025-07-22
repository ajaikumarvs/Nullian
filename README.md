# NullOS

A customized Debian distribution with GNOME desktop environment, productivity tools, and development packages.

## Features

- Based on Debian 12 (Bookworm)
- GNOME desktop environment
- LibreOffice suite 
- Visual Studio Code Insiders via Snap
- Enhanced ZSH with autocompletion
- Custom wallpapers and themes
- Custom bootloader animation

## Requirements

To build this distribution, you need:

- A Debian-based distribution (Debian or Ubuntu recommended)
- At least 20GB free disk space
- Packages: live-build, debootstrap, xorriso, isolinux, syslinux-common

## Building

1. Clone this repository:
   ```bash
   git clone https://github.com/ajaikumarvs/nullos.git
   cd nullos
   ```

2. Run the build script:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

3. The ISO file will be generated in the `output` directory.

## Customization

### Adding Packages

Edit the files in `config/package-lists/` to add or remove packages.

### Custom Wallpapers

Place your wallpaper images in `assets/wallpapers/`. Make sure to include:
- `default.jpg` - Default wallpaper
- `default-dark.jpg` - Default dark mode wallpaper
- `lock.jpg` - Lock screen wallpaper

### GNOME Theme

Place your GNOME theme folders in `assets/themes/`.

### Boot Animation

Customize the GRUB boot animation by editing files in `assets/bootanimation/`:
- `background.png` - GRUB background image
- `theme.txt` - GRUB theme configuration
- Add any additional images needed for the theme

