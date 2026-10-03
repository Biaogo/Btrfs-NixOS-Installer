# Btrfs-NixOS-Installer

A streamlined, interactive script for automating NixOS installation with Btrfs subvolumes and optimized configurations.

## Features

- 🚀 Automated NixOS installation with smart defaults
- 📁 Btrfs subvolume layout with compression and SSD optimizations
- 🖥️ Desktop environments, or none for a TTY
- 💽 Initrd storage drivers taken from the machine, so the root UUID is visible at boot
- 🔐 Optional LUKS, with LVM activated in stage-1 before the root UUID is mounted
- 🔧 Configurable system settings with sensible defaults
- 💾 Automated disk partitioning with EFI support
- 🔄 Optional swap file configuration
- 🌍 Localization and timezone setup
- 🔐 Secure user account creation
- 📦 Nix channels configuration with home-manager integration

## Btrfs Layout

The script creates an optimized Btrfs layout with the following subvolumes:
- @ (root)
- @home (user data)
- @nix (nix store)
- @log (system logs)
- @.snapshots (system snapshots)
- @swap (optional swap file location)

## Supported Desktop Environments

- KDE Plasma 6
- KDE Plasma 5
- GNOME
- XFCE
- Budgie
- Deepin
- MATE
- Cinnamon
- Enlightenment
- LXQt
- Pantheon
- none (TTY only, for installing Hyprland or another compositor afterwards)

## Requirements

- NixOS live ISO
- UEFI-capable system
- Internet connection
- Root access

## Usage

```bash
# Clone the repository
git clone https://github.com/Biaogo/Btrfs-NixOS-Installer

# Make the script executable
chmod +x Btrfs-NixOS-Installer/btrfs-nixos-installer

# Run the installer
sudo bash Btrfs-NixOS-Installer/btrfs-nixos-installer
```

## Features in Detail

### System Configuration
- Automated hardware detection
- Optimized Btrfs mount options
- Zstd compression for all subvolumes
- SSD/HDD detection and optimization
- Configurable system locale and keyboard layout

### Security
- Secure password hashing
- User group management
- Wheel group sudo access
- Optional Firefox installation

### Desktop Integration
- Automatic display manager configuration
- Desktop-specific optimizations
- Network manager integration
- PipeWire audio setup

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use and modify for your own purposes.

## Disclaimer

Always review the generated configurations before installation. While this script aims to be safe and reliable, it's recommended to back up any important data before running it.

## Support

If you encounter any issues or have suggestions for improvements, please open an issue on GitHub.

---
**Note**: This script is maintained by the community and is not officially affiliated with NixOS.
