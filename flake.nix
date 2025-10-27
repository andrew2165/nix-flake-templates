{
  description = ''
    Please look inside the proper language folder. This file is only here, so
    the template option of `nix flake new` works!
  '';

  outputs = { self, ... }:
    let
      templates = {
        rlang = {
          path = ./rlang;
          description = "A simple starter rlang analysis template with RStudio";
        };
      };
    in {
      templates = templates;
      defaultTemplate = templates.rlang;
    };
}

