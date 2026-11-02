{
  description = "Please look inside the proper language folder. This file is only here, so the template option of `nix flake init` works!";

  outputs =
    { self, ... }:
    let
      templates = {
        rlang = {
          path = ./rlang;
          description = "A simple starter rlang analysis template with RStudio";
        };
        proteomics = {
          path = ./proteomics;
          description = "A simple starter proteomics analysis environment";
        };
        msstatsshiny = {
          path = ./msstatsshiny;
          description = "A simple starter MSstats analysis environment with MSstatsShiny";
        };
      };
    in
    {
      templates = templates;
      defaultTemplate = templates.rlang;
    };
}
