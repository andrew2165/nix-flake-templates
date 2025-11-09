{
  description = "A Nix-flake-based RStudio Analysis environment";
  # use: nix develop

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self , nixpkgs ,... }: let
    # system should match the system you are running on
    # system = "x86_64-linux";
    system = "aarch64-darwin";
  in {
    devShells."${system}".default = let
      pkgs = import nixpkgs {
        inherit system;
      };
    in pkgs.mkShell {
      # create an environment with required R Packages
      packages = with pkgs; [
	      (rWrapper.override{ packages = [rPackages.rstudio_prefs];})
        curlFull
        rPackages.curl
        (rstudioWrapper.override{ 
          packages = with rPackages; [ 
            tidyverse 
            drc 
            rstudio_prefs
          ]; # add new R packages (from nix) here to get tied in
        })
      ];

      # Also output rstudioPrefs for use in other flakes
      rstudioPrefs = ./rstudio-prefs.json

      shellHook = ''
	      R -e "require(rstudio.prefs); rstudio_config_path('./rstudio-prefs.json');"
        echo "RStudio Analysis Shell - ${system}"
	      rstudio
      '';
    };
  };
}
