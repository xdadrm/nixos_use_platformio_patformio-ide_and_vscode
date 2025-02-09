# User Guide: Portable PlatformIO Development Environment with VSCodium

## Summary

This guide outlines the steps necessary to set up a portable PlatformIO development environment using VSCodium on NixOS or other Nix-based systems. The configuration relies on `nixpkgs` for Python and PlatformIO, bypassing versions provided by the PlatformIO extension. This setup involves patching the PlatformIO VSCode extension to ensure compatibility.

**Warning:** This method is dependent on a work-in-progress pull request and modifies packages from the Visual Studio Marketplace. Consequently, it may break in the future.

### Usage

The quickest way to use this flake to work on a `platformio` project:

1. Go to your project repo
2. Enter the devshell:
   ```
   nix develop github:xdadrm/nixos_use_platformio_patformio-ide_and_vscode
   ```
3. `codium .`

### Modify devshell

If you need to modify something in the devshell:

1. Clone the repository containing the `flake.nix` file.
2. Run `nix develop --build`.
3. Launch VSCodium using the provided `codium` function within the shell (Note: `pio` is also available and working).

```bash
git clone https://github.com/xdadrm/nixos_use_platformio_patformio-ide_and_vscode.git
cd nixos_use_platformio_patformio-ide_and_vscode
nix develop --build
codium .
```

## Detailed Guide

### Prerequisites

- **NixOS**: on x86-64 [official installation guide](https://nixos.org/download.html).
- **Git**: Install Git to clone the repository containing the `flake.nix` file.

### Setup Instructions

#### 1. Clone the Repository

Clone the repository containing the `flake.nix` file to your local machine:

```bash
git clone <repository-url>
cd <repository-directory>
```

#### 2. Enter the Development Shell

Use the following command to enter the development shell, which provides all the necessary tools (PlatformIO, Python, VSCodium, and Git):

```bash
nix develop --build
```

#### 3. Launch VSCodium

After running the setup script, you can launch VSCodium with the following command:

```bash
codium
```

This command ensures that VSCodium uses the custom settings and the patched PlatformIO extension.

#### 4. (Optional) Customize Environment Variables

You can customize the following environment variables:

- `PLATFORMIO_CORE_DIR`: Specifies the directory for PlatformIO core files (default: `$PWD/.platformio`).
- `VSCODE_DATA_DIR`: Specifies the directory for VSCodium user data (default: `$PWD/.vscode-data`).

For example:

```bash
export PLATFORMIO_CORE_DIR=/path/to/custom/platformio
export VSCODE_DATA_DIR=/path/to/custom/vscode-data
```

### Conclusion

This setup provides a portable, reproducible, and customizable PlatformIO development environment using VSCodium. By leveraging Nix, you can ensure that your development environment is consistent across different machines and projects.

For more details, refer to the `flake.nix` file and its associated functions (`platformioEnv`, `patchedExtension`, `vscodiumSettings`, and `setupScript`).

### Credits

This guide builds upon [ppenguin's PR-237313](https://github.com/NixOS/nixpkgs/pull/237313) along with [delan's](https://github.com/NixOS/nixpkgs/pull/237313#issuecomment-1848198106) approach documented in the wiki: [PlatformIO Nix Wiki](https://nixos.wiki/index.php?title=Platformio&oldid=10699).
