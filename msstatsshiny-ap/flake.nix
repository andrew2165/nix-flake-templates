{
  description = "MSstats Affinity Profiling with MSstatsShinyAP";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    msstats-ap = {
      url = "github:andrew2165/MSstats-AP/757cde8bb22d5c37356a1aa52bc48c69b929211a";
      flake = false;
    };
    msstats-tmt-ap = {
      url = "github:andrew2165/MSstatsTMT-AP/b9a30b12c4f951f805496e2b43661b7872f0b801";
      flake = false;
    };
    msstats-shiny-ap = {
      url = "github:andrew2165/MSstatsShiny-AP/fdbaca4f54bd1ce174b216e1a21784dcf1739351";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      msstats-ap,
      msstats-tmt-ap,
      msstats-shiny-ap,
    }:
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
          # The Shiny fork imports APIs introduced in Bioconductor 3.23.
          buildBiocDependency =
            pname: version: hash: propagatedBuildInputs:
            pkgs.rPackages.buildRPackage {
              inherit pname version propagatedBuildInputs;
              src = pkgs.fetchurl {
                inherit hash;
                urls = [
                  "mirror://bioc/3.23/bioc/src/contrib/${pname}_${version}.tar.gz"
                  "mirror://bioc/3.23/bioc/src/contrib/Archive/${pname}/${pname}_${version}.tar.gz"
                ];
              };
            };

          rPackages = pkgs.rPackages // {
            MSstatsBioNet = buildBiocDependency "MSstatsBioNet" "1.4.1" "sha256-2RInvhH35vgA3/DTjOF0gcAeLHUFO6t9krVKI/LS7Mg=" (
              with pkgs.rPackages;
              [
                MSstats
                httr
                jsonlite
                r2r
                tidyr
                htmlwidgets
                text2vec
                stopwords
                xml2
                rentrez
              ]
            );
            MSstatsResponse = buildBiocDependency "MSstatsResponse" "1.2.0" "sha256-x6V5nEQO3yUYdTMlrWAG/8uqSaNYw6tveLRHm8oHkNE=" (
              with pkgs.rPackages;
              [
                BiocParallel
                ggplot2
                dplyr
                data_table
                tidyr
                stringr
                plotly
              ]
            );
          };

          buildFork =
            pname: version: src: propagatedBuildInputs:
            rPackages.buildRPackage {
              inherit pname version propagatedBuildInputs;
              src = src.outPath;
              postPatch = ''
                printf 'RemoteSha: %s\n' '${src.rev}' >> DESCRIPTION
              '';
            };

          MSstatsAP = buildFork "MSstatsAP" "4.20.0" msstats-ap (
            with rPackages;
            [
              MSstatsConvert
              data_table
              checkmate
              MASS
              htmltools
              limma
              lme4
              preprocessCore
              survival
              Rcpp
              RcppArmadillo
              ggplot2
              ggrepel
              gplots
              plotly
              marray
              statmod
              rlang
            ]
          );

          MSstatsTMTAP = buildFork "MSstatsTMTAP" "2.20.0" msstats-tmt-ap (
            with rPackages;
            [
              MSstatsAP
              MSstatsConvert
              limma
              lme4
              lmerTest
              data_table
              ggplot2
              checkmate
              plotly
              htmltools
            ]
          );

          MSstatsShinyAP = buildFork "MSstatsShinyAP" "1.14.0" msstats-shiny-ap (
            with rPackages;
            [
              MSstatsAP
              MSstatsTMTAP
              MSstatsBig
              MSstatsPTM
              MSstatsConvert
              MSstatsBioNet
              MSstatsResponse
              shiny
              shinyBS
              shinyjs
              shinybusy
              dplyr
              ggplot2
              plotly
              data_table
              Hmisc
              shinyFiles
              gplots
              marray
              DT
              readxl
              ggrepel
              uuid
              htmltools
              tidyr
              mockery
              shinydashboard
              arrow
              stringr
              httr
            ]
          );

          baseREnvironment = pkgs.rWrapper.override {
            packages = [
              MSstatsAP
              MSstatsTMTAP
              MSstatsShinyAP
            ];
          };

          rEnvironment = pkgs.symlinkJoin {
            name = "msstats-ap-r";
            paths = [ baseREnvironment ];
            nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
            # Shiny uses utils::zip() when exporting plots.
            postBuild = ''
              for exe in R Rscript; do
                wrapProgram "$out/bin/$exe" \
                  --set-default R_ZIPCMD "${pkgs.zip}/bin/zip" \
                  --set-default R_UNZIPCMD "${pkgs.unzip}/bin/unzip"
              done
            '';
          };

          shinyLauncher = pkgs.writeText "launch-msstats-ap.R" ''
            port_text <- Sys.getenv("MSSTATS_PORT", "3838")
            port <- suppressWarnings(as.integer(port_text))
            if (!grepl("^[0-9]+$", port_text) || is.na(port) || port < 1L || port > 65535L) {
              stop("MSSTATS_PORT must be an integer between 1 and 65535")
            }
            host <- Sys.getenv("MSSTATS_HOST", "127.0.0.1")
            open_browser <- Sys.getenv("MSSTATS_OPEN_BROWSER", "1") == "1"

            app <- MSstatsShinyAP::launch_MSstatsShiny(host = host, port = port)
            shiny::runApp(app, host = host, port = port, launch.browser = open_browser)
          '';

          browser = if pkgs.stdenv.hostPlatform.isDarwin then "/usr/bin/open" else "${pkgs.xdg-utils}/bin/xdg-open";

          msstatsShiny = pkgs.writeShellApplication {
            name = "msstats-shiny";
            text = ''
              unset R_LIBS R_LIBS_SITE
              export R_LIBS_USER=/nonexistent
              export R_BROWSER="''${R_BROWSER:-${browser}}"
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
          default = {
            type = "app";
            program = "${packages.msstats-shiny}/bin/msstats-shiny";
            meta.description = "Launch MSstatsShinyAP";
          };
          r = {
            type = "app";
            program = "${packages.r}/bin/R";
            meta.description = "Start R with the MSstats AP forks";
          };
          rscript = {
            type = "app";
            program = "${packages.r}/bin/Rscript";
            meta.description = "Run a script with the MSstats AP forks";
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
              echo "Run msstats-shiny for the browser app or R --vanilla for R."
            '';
          };
        }
      );
    };
}
