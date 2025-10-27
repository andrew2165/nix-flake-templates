# Nix Analysis/Dev Environments

This is my repo for all of my nix development and analysis flake *templates*.
The general purpose is to serve as a jumping off point for flakes that
I re-use frequently.

For anyone who finds this and is not familiar with the benefits of Nix the
10,000 ft overview is that this workflow provides a single way to standardize
dependencies across different languages. So one project could be statistical
analysis using Rlang using one of these templates and another could be a
monte-carlo model written in Python BUT all of the dependencies are managed
in the same way between both projects (using nix). The other main benefit is
that it can allow complete pinning of dependencies, so I can delete everything
and as long as I have a copy of the flake and the code I can, with a single command,
get back to a running environment.

## Example Usage

Here is an example workflow for a new RStudio-based analysis project:

```bash
mkdir new_rlang_analysis
cd new_rlang_analysis
git init
nix flake init -t github:andrew2165/r-analysis-env#rlang
```

Then edit the new flake to include the desired packages/environmental variables
and to pin the dependencies (one of the whole reasons to use flakes). 

E.g., altering line #6 in [./rlang/flake.nix](./rland/flake.nix) from

```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
```

to 

```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
```


and then proceed with the analysis or development!
