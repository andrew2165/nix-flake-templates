{
  description = "A Nix-flake-based Proteomics Analysis environment";
  # use: nix develop

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self , nixpkgs , ... }: let
    # system should match the system you are running on
    # system = "x86_64-linux";
    system = "aarch64-darwin";
  in {
    devShells."${system}".default = let

      pkgs = import nixpkgs {
        inherit system;
      };

      fragpipeSrc = pkgs.fetchFromGitHub {
        owner = "Nesvilab";
        repo = "philosopher";
        rev = "v5.1.0";
        sha256 = "sha256-nLSTDHJCNFEQi4O01plVbR361B943pCt9g1sZlYx0gA=";
      };

      # Path to the starter shell script
      fragpipeShellScript = "${fragpipeSrc}/FragPipe-GUI/start-scripts/fragpipe.sh";
      
    in pkgs.mkShell {
        #packages = with pkgs; [ ];

        shellHook = ''
        alias fragpipe="${fragpipeShellScript}";
        echo "---- Proteomics Analysis Shell ----"
        echo "Aliased 'fragpipe' to ${fragpipeShellScript}"
        '';
    };
  };
}
