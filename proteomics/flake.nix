{
  description = "A Nix-flake-based Proteomics Analysis environment";
  # use: nix develop

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
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
              # writeShellScriptBin is from pkgs itself, no extra package required
              (writeShellScriptBin "fragpipe" ''
                #!/usr/bin/env bash
                set -euo pipefail

                # Respect XDG dirs or fall back to sane defaults
                : "${XDG_DATA_HOME:=$HOME/.local/share}"
                : "${XDG_CONFIG_HOME:=$HOME/.config}"
                : "${XDG_CACHE_HOME:=$HOME/.cache}"

                # Prepare ephemeral runtime dir under TMP; per-run copy
                TMPROOT="${TMPDIR:-/tmp}/fragpipe-${USER}"
                mkdir -p "$TMPROOT"
                RUNTIME_DIR="$(mktemp -d "$TMPROOT/run-XXXXXX")"

                # Attempt copy with reflinks when supported (faster / space-efficient), fall back to plain copy
                if ! (cp --reflink=auto -a "${fragpipeSrc}/." "$RUNTIME_DIR/" 2>/dev/null); then
                  cp -a "${fragpipeSrc}/." "$RUNTIME_DIR/"
                fi

                # Ensure some writable dirs and sensible Java tmpdir
                mkdir -p "$XDG_CACHE_HOME/fragpipe" "$XDG_CONFIG_HOME/FragPipe" "$RUNTIME_DIR/tmp"
                export JAVA_HOME="${pkgs.openjdk}"
                export PATH="${pkgs.openjdk}/bin:$PATH"
                export JAVA_OPTS="${JAVA_OPTS:-} -Djava.io.tmpdir=$RUNTIME_DIR/tmp"

                # Upstream-friendly env var that some pipelines check
                export FRAGPIPE_HOME="$RUNTIME_DIR"

                # Exec the FragPipe binary from the ephemeral copy
                exec "$RUNTIME_DIR/bin/fragpipe" "$@"
              '')
            ];

            shellHook = ''
              echo "---- Proteomics Analysis Shell ----"
              echo "Wrapper 'fragpipe' available: copies FragPipe to a temporary writable dir and runs it."
            '';
          };
        }
      );
    };
}
