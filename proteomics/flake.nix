{
  description = "A Nix-flake-based Proteomics Analysis environment";
  # use: nix develop

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    rlangFlake.url = "github:andrew2165/nix-flake-templates?dir=rlang";
  };

  outputs =
    {
      self,
      nixpkgs,
      rlangFlake,
      ...
    }:
    let

      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # FragPipe Version
      # (assumes they keep url versioning and naming consistent)
      version = "23.1";
    in
    {
      devShells = forAllSystems (
        system:
        let

          pkgs = import nixpkgs {
            inherit system;
          };

          fragpipeSrc = pkgs.fetchzip {
            url = "https://github.com/Nesvilab/FragPipe/releases/download/${version}/FragPipe-${version}-linux.zip";
            sha256 = "sha256-IIG8WvcpUCChpHZwVDbiMkwWIFrbElt4fagOBeLU560=";
          };

          # Note: we create a runtime wrapper below (writeShellScriptBin "fragpipe")
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              openjdk
              unzip
              python312 # and then any other python packages required

              # RStudio and Packages
              (rWrapper.override { packages = [ rPackages.rstudio_prefs ]; })
              curlFull
              rPackages.curl
              (rstudioWrapper.override {
                packages = with rPackages; [
                  tidyverse
                  drc
                  rstudio_prefs
                ]; # add new R packages (from nix) here to get tied in
              })

              # FragPipe
              # writeShellScriptBin is from pkgs itself, no extra package required
              (pkgs.writeShellScriptBin "fragpipe" ''
                set -euo pipefail

                # Create a unique temporary directory in /tmp for this FragPipe session
                RUNTIME_DIR=$(mktemp -d /tmp/fragpipe-XXXXXXXX)
                trap 'rm -rf "$RUNTIME_DIR"' EXIT

                # Copy FragPipe files to the temporary directory
                cp -a "${fragpipeSrc}/." "$RUNTIME_DIR/"

                chmod -R u+rwX "$RUNTIME_DIR"

                # Run FragPipe from the ephemeral copy, forwarding all args
                exec "$RUNTIME_DIR/bin/fragpipe" "$@"
              '')
            ];

            shellHook = ''
              cp ${rlangFlake.rstudioPrefs} ./rstudio-prefs.json
              chmod u+w ./rstudio-prefs.json
              R -e "require(rstudio.prefs); rstudio_config_path('./rstudio-prefs.json');"
 
              echo "---- Proteomics Analysis Shell ----"
              echo "Wrapper 'fragpipe' available: copies FragPipe to a temporary writable dir and runs it."
            '';
          };
        }
      );
    };
}
