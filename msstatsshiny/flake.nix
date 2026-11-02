{
  description = "A Nix-flake-based MSstats Analysis environment with MSstatsShiny";
  # Web app: nix run
  # R shell: nix develop

  inputs = {
    # Use the stable 26.05 release; flake.lock pins the exact revision.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          # R and all R packages are managed by Nix.
          rEnvironment = pkgs.rWrapper.override {
            packages = with pkgs.rPackages; [
              MSstats
              MSstatsShiny
              # Add additional R packages (from nixpkgs) here.
            ];
          };

          # Store the R launcher in the Nix store alongside the packages.
          # Override the defaults with MSSTATS_PORT or MSSTATS_HOST.
          shinyLauncher = pkgs.writeText "launch-msstats.R" ''
            port <- suppressWarnings(as.integer(Sys.getenv("MSSTATS_PORT", "3838")))
            if (is.na(port) || port < 1L || port > 65535L) {
              stop("MSSTATS_PORT must be an integer between 1 and 65535")
            }
            host <- Sys.getenv("MSSTATS_HOST", "127.0.0.1")

            app <- MSstatsShiny::launch_MSstatsShiny(port = port, host = host)
            shiny::runApp(app, host = host, port = port, launch.browser = FALSE)
          '';

          msstatsShiny = pkgs.writeShellApplication {
            name = "msstats-shiny";
            text = ''
              # Use Nix packages and ignore user R startup files.
              export R_LIBS_USER=/nonexistent
              exec ${rEnvironment}/bin/Rscript --vanilla ${shinyLauncher} "$@"
            '';
          };
        in
        {
          default = msstatsShiny;
          msstats-shiny = msstatsShiny;
          r = rEnvironment;
        }
      );

      apps = forAllSystems (
        system:
        let
          packages = self.packages.${system};
        in
        {
          # nix run
          default = {
            type = "app";
            program = "${packages.msstats-shiny}/bin/msstats-shiny";
          };

          # nix run .#r -- --vanilla
          r = {
            type = "app";
            program = "${packages.r}/bin/R";
          };

          # nix run .#rscript -- --vanilla analysis.R
          rscript = {
            type = "app";
            program = "${packages.r}/bin/Rscript";
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          packages = self.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              packages.r
              packages.msstats-shiny
            ];

            R_LIBS_USER = "/nonexistent";

            shellHook = ''
              echo "---- MSstats Analysis Shell ----"
              echo "Run R --vanilla for R, or msstats-shiny for the web app."
              echo "Default web address: http://127.0.0.1:3838"
            '';
          };
        }
      );
    };
}
