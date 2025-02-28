# Portable PlatformIO Development Environment with VSCodium

This flake provides a working PlatformIO development environment using VSCodium on NixOS or other Nix-based systems. It leverages `nixpkgs` for Python and PlatformIO, ensuring compatibility while bypassing the versions provided by the PlatformIO extension.

**Note:** This method involves patching the PlatformIO VSCode extension and using overrides in the Python environment. It may break in the future due to updates or changes in dependencies.

---

## Quick Start

### Option 1: Start VSCodium Directly
Run the following command to launch VSCodium with the PlatformIO environment pre-configured. You can also pass options such as `--help` to VSCodium:
```bash
nix run --impure github:xdadrm/nixos_use_platformio_patformio-ide_and_vscode#codium -- .
```

### Option 2: Open a Development Shell
To open a shell with VSCodium, PlatformIO (`pio`), and `tio` available, use:
```bash
nix develop --impure github:xdadrm/nixos_use_platformio_patformio-ide_and_vscode
```

---

## Customizing the Development Environment

If you want to modify the development environment, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/xdadrm/nixos_use_platformio_patformio-ide_and_vscode.git
   cd nixos_use_platformio_patformio-ide_and_vscode
   ```

2. Enter the development shell and launch VSCodium:
   ```bash
   nix develop --impure .#
   codium .
   ```

---

## Detailed Setup Guide

### Prerequisites
- **NixOS**: Installed on an x86-64 system. Follow the [official installation guide](https://nixos.org/download.html).
- **Git**: Required to clone the repository.

---

### How It Works

This setup allows you to use VSCodium with the PlatformIO IDE extension on NixOS. It modifies your existing VSCodium configuration by:
- Adding the PlatformIO extension.
- Adjusting settings of the PlatformIO extension to ensure compatibility.

Since the extension automatically downloads new PlatformIO Core versions, the setup is not "pure." Using the `--impure` flag allows the system to reuse the system's `nixpkgs` instead of downloading a specific version.

**Important:** Two versions of PlatformIO will be installed:
1. A native version provided by `nixpkgs`, available regardless of whether the PlatformIO IDE extension has downloaded PlatformIO Core.
2. A version installed by the PlatformIO IDE extension (currently 1.6.17). The extension always installs the latest version, which may diverge from the native version.

For consistency, this flake will prefer the PlatformIO IDE's version if available via the `PATH` variable.

---

### Credits

This approach builds upon but does not depend on:
- [ppenguin's PR-237313](https://github.com/NixOS/nixpkgs/pull/237313).
- [delan's approach](https://github.com/NixOS/nixpkgs/pull/237313#issuecomment-1848198106) documented in the [PlatformIO Nix Wiki](https://nixos.wiki/index.php?title=Platformio&oldid=10699).

---

## Troubleshooting

- **Conda Conflicts**: If you have Conda in your default shell (e.g., `.bashrc`), it may interfere with this flake, resulting in missing modules or other Python errors. Temporarily disable Conda initialization or use a clean shell environment.

---

## Contributing

If you encounter issues or have suggestions for improvement, feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/xdadrm/nixos_use_platformio_patformio-ide_and_vscode).

---

