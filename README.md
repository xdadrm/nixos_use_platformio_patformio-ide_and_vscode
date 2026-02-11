# Portable PlatformIO Development Environment with VSCodium

This flake provides a working PlatformIO development environment using VSCodium on NixOS or other Nix-based systems. It leverages `nixpkgs` for Python and PlatformIO, ensuring compatibility while bypassing the versions provided by the PlatformIO extension.

**Note:** This method involves patching the PlatformIO VSCode extension and using overrides in the Python environment. It may break in the future due to updates or changes in dependencies.

# Usage Guide

This flake provides a specialized FHS (Filesystem Hierarchy Standard) environment required for PlatformIO to manage its own toolchains on NixOS.

## 1. Run without Installing

### Start VSCodium with PlatformIO/pio enabled, you can also pass options such as `--help` to VSCodium
```bash
nix run --impure github:xdadrm/nixos_use_platformio_patformio-ide_and_vscode#codium -- .
```

### Enter a PlatformIO Shell
Use this to run `pio` commands or launch the vscodium IDE manually. This also makes the `tio` serial terminal available.
```bash
nix develop --impure github:xdadrm/nixos_use_platformio_patformio-ide_and_vscode
# Inside the shell:
Codium-PIO> pio run
Codium-PIO> codium .
Codium-PIO> tio -b 9600 /dev/ttyUSB0
```

---

## 2. Persistent Installation
If you use PlatformIO and vscodium every day, you may prefer to have the commands available globally in your path.

### Install the IDE Launcher
```bash
nix profile add --impure github:xdadrm/nixos_use_platformio_patformio-ide_and_vscode#codium
```
*Usage:* `codium-launcher .`

### Install the Full Environment Wrapper
```bash
nix profile add --impure github:xdadrm/nixos_use_platformio_patformio-ide_and_vscode
```
*Usage:*
- **Interactive:** `platformio-env` (then run `pio`, `codium`, or `tio`)
- **One-liner:** `echo "codium ." | platformio-env`

---
