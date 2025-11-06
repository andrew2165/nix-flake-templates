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

          # Path to the starter shell script
          fragpipeShellScript = "${fragpipeSrc}/bin/fragpipe";

        in
        {
          default = pkgs.mkShell {
            #packages = with pkgs; [ ];
            packages = with pkgs; [
              openjdk
              unzip
            ];

            shellHook = ''
              alias fragpipe="${fragpipeShellScript}";
              echo "---- Proteomics Analysis Shell ----"
              echo "Aliased 'fragpipe' to ${fragpipeShellScript}"
            '';
          };
        }
      );
    };
}
