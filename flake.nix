{
  description = "PlatformIO Development Environment with VSCodium";

  inputs = {
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import <nixpkgs> { inherit system; };

      platformioVsix = pkgs.fetchurl {
        url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/platformio/vsextensions/platformio-ide/3.3.4/vspackage?targetPlatform=linux-x64";
        sha256 = "sha256-Ri5TZDxSsW1cW33Rh+l/5Fxl23MNzFEjcFGLDx/xzT8=";
      };

      patchedExtension = pkgs.stdenv.mkDerivation {
        name = "platformio-ide-patched";
        src = platformioVsix;
        buildInputs = [ pkgs.jq pkgs.unzip pkgs.gzip ];
        unpackCmd = ''
          gzip -d < $src > temp.zip
          unzip temp.zip
          rm temp.zip
        '';
        buildPhase = ''
          jq '.extensionDependencies = [] |
              .["platformio-ide.useBuiltinPIOCore"].default = false |
              .["platformio-ide.useBuiltinPython"].default = false |
              .["platformio-ide.forceSystemPIOCore"].default = true |
              .["platformio-ide.forceSystemPython"].default = true' \
              package.json > package.json.new
          mv package.json.new package.json
        '';
        installPhase = ''
          cd ..
          mkdir -p $out
          ${pkgs.zip}/bin/zip -r $out/platformio-ide.vsix .
        '';
      };

      platformioWrapper = pkgs.writeScriptBin "platformio" ''
        #!/bin/sh
        VENV_DIR="''${PLATFORMIO_VENV_DIR:-$HOME/.platformio/penv}"
        . "$VENV_DIR/bin/activate"
        exec ${pkgs.platformio}/bin/platformio "$@"
      '';

      configureVSCodeSettings = ''
        USER_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User"
        mkdir -p "$USER_CONFIG_DIR"
        SETTINGS_FILE="$USER_CONFIG_DIR/settings.json"
        if [ ! -f "$SETTINGS_FILE" ]; then
          echo '{}' > "$SETTINGS_FILE"
        fi
        ${pkgs.jq}/bin/jq '. + {
          "platformio-ide.useBuiltinPIOCore": true,
          "platformio-ide.useBuiltinPython": false,
          "platformio-ide.forceSystemPIOCore": false,
          "platformio-ide.forceSystemPython": true,
          "platformio-ide.customPATH": "$PATH"
        }' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
        if [ $? -eq 0 ]; then
          mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        else
          rm -f "$SETTINGS_FILE.tmp"
        fi
      '';

      fhsEnv = pkgs.buildFHSEnv {
        name = "platformio-env";
        targetPkgs = pkgs: with pkgs; [
          platformio
          platformioWrapper
          python312
          git
          vscodium
          gcc
          gdb
          gnumake
          udev
          zlib
          ncurses
          stdenv.cc.cc.lib
          glibc
          libusb1
          openssl
          tio
        ];
        profile = ''
          export PYTHONPATH=${pkgs.platformio}/lib/python3.12/site-packages:$PYTHONPATH
          export PLATFORMIO_CORE_DIR="''${PLATFORMIO_CORE_DIR:-$HOME/.platformio}"
          export PATH=${platformioWrapper}/bin:$PATH
          export PATH=${pkgs.python312}/bin:$PATH
        '';
        runScript = pkgs.writeScript "platformio-shell" ''
          export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
          export PATH=${pkgs.python312}/bin:${platformioWrapper}/bin:$PATH
          export PYTHONPATH=${pkgs.platformio}/lib/python3.12/site-packages:$PYTHONPATH
          ${configureVSCodeSettings}
          VSCODE_PORTABLE="''${VSCODE_PORTABLE:-$HOME/.vscode-portable}"
          EXTENSION_DIR="''${VSCODE_PORTABLE}/extensions"
          mkdir -p "$EXTENSION_DIR"
          ${pkgs.vscodium}/bin/codium --install-extension ${patchedExtension}/platformio-ide.vsix
          mkdir -p $HOME/.local/bin
          ln -sf ${platformioWrapper}/bin/platformio $HOME/.local/bin/pio
          echo "PlatformIO environment ready. PlatformIO Core: $(platformio --version)"
          echo "Run 'codium .' to open VSCodium in current directory"
          if [ -f $HOME/.platformio/penv/bin/activate ]; then
             source $HOME/.platformio/penv/bin/activate
          fi
          PS1="Codium-PIO> "
          exec bash --norc
        '';
      };

      # Create a dedicated VSCodium launcher package that accepts arguments
      codiumLauncher = pkgs.writeScriptBin "launch-codium" ''
        #!/usr/bin/env bash
        export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
        export PATH=${pkgs.python312}/bin:${platformioWrapper}/bin:$PATH
        export PYTHONPATH=${pkgs.platformio}/lib/python3.12/site-packages:$PYTHONPATH
        ${configureVSCodeSettings}
        VSCODE_PORTABLE="''${VSCODE_PORTABLE:-$HOME/.vscode-portable}"
        EXTENSION_DIR="''${VSCODE_PORTABLE}/extensions"
        mkdir -p "$EXTENSION_DIR"
        ${pkgs.vscodium}/bin/codium --install-extension ${patchedExtension}/platformio-ide.vsix
        mkdir -p $HOME/.local/bin
        ln -sf ${platformioWrapper}/bin/platformio $HOME/.local/bin/pio
        
        # Initialize PlatformIO environment if needed
        if [ ! -f $HOME/.platformio/penv/bin/activate ] && [ -x "$(command -v python3)" ]; then
          echo "Initializing PlatformIO environment..."
          python3 -c "$(curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py)"
        fi
        
        if [ -f $HOME/.platformio/penv/bin/activate ]; then
          source $HOME/.platformio/penv/bin/activate
        fi
        
        # If no arguments are provided, open the current directory
        if [ $# -eq 0 ]; then
          exec ${pkgs.vscodium}/bin/codium .
        else
          # Otherwise, pass all arguments to VSCodium
          exec ${pkgs.vscodium}/bin/codium "$@"
        fi
      '';

      # Create an FHS environment specifically for launching VSCodium
      codiumFhsEnv = pkgs.buildFHSEnv {
        name = "codium-launcher";
        targetPkgs = pkgs: with pkgs; [
          platformio
          platformioWrapper
          python312
          git
          vscodium
          gcc
          gdb
          gnumake
          udev
          zlib
          ncurses
          stdenv.cc.cc.lib
          glibc
          libusb1
          openssl
          codiumLauncher
          tio
        ];
        profile = ''
          export PYTHONPATH=${pkgs.platformio}/lib/python3.12/site-packages:$PYTHONPATH
          export PLATFORMIO_CORE_DIR="''${PLATFORMIO_CORE_DIR:-$HOME/.platformio}"
          export PATH=${platformioWrapper}/bin:$PATH
          export PATH=${pkgs.python312}/bin:$PATH
        '';
        # Pass all arguments received to the launch-codium script
        runScript = pkgs.writeScript "codium-launch-wrapper" ''
          exec ${codiumLauncher}/bin/launch-codium "$@"
        '';
      };

    in
    {
      devShells.${system} = {
        default = fhsEnv.env;
        codium = codiumFhsEnv.env;
      };

      packages.${system} = {
        default = fhsEnv;
        platformioExtension = patchedExtension;
        codium = codiumFhsEnv;
      };
    };
}
