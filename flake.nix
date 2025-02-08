{
  description = "Portable PlatformIO development environment with VSCodium";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/pull/237313/head";  # Use a specific nixpkgs revision
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";  # Explicitly define the system
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (self: super: {
            # Override platformio-core to include pip in propagatedBuildInputs
            platformio-core = super.platformio-core.overrideAttrs (old: {
              propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.python3Packages.pip ];
            });
          })
        ];
      };

      # Fetch the PlatformIO VSCode extension from the marketplace
      platformioVsix = pkgs.fetchurl {
        url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/platformio/vsextensions/platformio-ide/3.3.4/vspackage";
        sha256 = "sha256-CXIP6+ZxjLik9VxG7xrX53FXQBCGgTGhhskYAR32w6o=";
      };

      # Patch the PlatformIO extension to remove dependencies and modify settings
      patchedExtension = pkgs.stdenv.mkDerivation {
        name = "platformio-ide-patched";
        src = platformioVsix;
        buildInputs = [ pkgs.jq pkgs.unzip pkgs.gzip ];  # Tools needed for patching
        unpackCmd = ''
          # First, decompress the .gz file
          gzip -d < $src > temp.zip
          # Then, unzip the resulting .zip file
          unzip temp.zip
          rm temp.zip
        '';
        buildPhase = ''
          # Modify package.json to remove extension dependencies and disable built-in Python/PIO
          jq '.extensionDependencies = [] |
              .["platformio-ide.useBuiltinPython"].default = false |
              .["platformio-ide.useBuiltinPIOCore"].default = false' \
              package.json > package.json.new
          mv package.json.new package.json
        '';
        installPhase = ''
          cd ..
          mkdir -p $out
          # Repackage the modified extension (will be in result)
          ${pkgs.zip}/bin/zip -r $out/platformio-ide.vsix .
        '';
      };

      # Generate VSCodium settings to use the system's PlatformIO installation
      vscodiumSettings = pkgs.writeText "settings.json" (builtins.toJSON {
          "platformio-ide.useBuiltinPIOCore" = false;
          "platformio-ide.useBuiltinPython" = false;
          "platformio-ide.customPATH" = "${pkgs.platformio-core}/bin";
      });

      # Script to set up VSCodium with the patched PlatformIO extension
      setupScript = pkgs.writeShellScriptBin "setup-platformio-ide" ''
        mkdir -p .vscode
        cp ${vscodiumSettings} .vscode/settings.json
        VSCODE_DATA_DIR="''${VSCODE_DATA_DIR:-$PWD/.vscode-data}"
        mkdir -p "$VSCODE_DATA_DIR"
        ${pkgs.vscodium}/bin/codium \
          --user-data-dir "$VSCODE_DATA_DIR" \
          --install-extension ${patchedExtension}/platformio-ide.vsix
      '';

      # Create an FHS environment with PlatformIO, Python, VSCodium, and Git
      platformioEnv = pkgs.buildFHSEnv {
        name = "platformio-env";
        targetPkgs = pkgs: (with pkgs; [
          platformio-core
          (python3.withPackages (ps: [ ps.platformio ]))  # Python with PlatformIO package
          vscodium
          git
        ]);
        runScript = pkgs.writeScript "platformio-shell" ''
          export PLATFORMIO_CORE_DIR="''${PLATFORMIO_CORE_DIR:-$PWD/.platformio}"  # Set PlatformIO directory
          export VSCODE_DATA_DIR="''${VSCODE_DATA_DIR:-$PWD/.vscode-data}"  # Set VSCodium data directory

          # Run the setup script to install the PlatformIO extension
          ${setupScript}/bin/setup-platformio-ide

          function codium() {
            ${pkgs.vscodium}/bin/codium --user-data-dir "$VSCODE_DATA_DIR" "$@"
          }

          exec bash
        '';
      };

    in {
      devShells.${system}.default = platformioEnv.env;  # Default dev shell is the PlatformIO environment
      apps.${system}.default = {  # Default app is the setup script
        type = "app";
        program = "${setupScript}/bin/setup-platformio-ide";
      };
      packages.${system}.default = patchedExtension;  # Default package is the patched extension
    };
}