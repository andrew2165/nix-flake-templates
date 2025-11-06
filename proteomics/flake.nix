{
  description = "A Nix-flake-based Proteomics Analysis environment";
  # use: nix develop

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      # system should match the system you are running on
      # system = "x86_64-linux";
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # FragPipe Version
      # (assumes they keep versioning and naming consistent)
      version = "23.1";
    in
    {
      devShells = forAllSystems (
        system:
        let
          #."${system}".default = let
          pkgs = import nixpkgs {
            inherit system;
          };
          # fragpipeSrc = pkgs.fetchFromGitHub {
          #   owner = "Nesvilab";
          #   repo = "FragPipe";
          #   rev = "d8bf745";
          #   sha256 = "0000000000000000000000000000000000000000000000000000";
          # };
          fragpipeSrc = pkgs.fetchzip {
            # URL pattern for the release asset:
            # https://github.com/Nesvilab/FragPipe/releases/download/23.1/FragPipe-23.1-linux.zip
            url = "https://github.com/Nesvilab/FragPipe/releases/download/${version}/FragPipe-${version}-linux.zip";
            # Put the correct hash here (see instructions below to prefetch).
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
