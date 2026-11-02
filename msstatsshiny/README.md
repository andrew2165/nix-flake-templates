# MSstats practice environment

All package definitions and launch code are in `flake.nix`; `flake.lock` fixes
the exact revision within the stable `nixos-26.05` release. R and its packages are installed in `/nix/store`.
Your uploaded data, analysis results, and temporary files remain writable data.

From this directory, launch the web app:

```sh
nix run path:.
```

Open http://127.0.0.1:3838. Stop a foreground launch with Ctrl-C.
To select another port: `MSSTATS_PORT=3839 nix run path:.`.

Start R with MSstats and MSstatsShiny available:

```sh
nix run path:.#r -- --vanilla
```

```r
library(MSstats)
library(MSstatsShiny)
system.file("extdata", "tutorial", package = "MSstatsShiny")
```

The final command locates the upstream practice files inside the Nix store.
You can copy data files to a working directory to select them in the upload dialog.
See the [upstream tutorial](https://github.com/Vitek-Lab/MSstatsShiny#readme)
for the FragPipe practice workflow.

`nix develop path:.` provides both R and `msstats-shiny` in a shell.
Avoid `install.packages()` or `BiocManager::install()`; add any additional
packages to the flake's `rWrapper` package list and rebuild instead.

This template supports Apple Silicon macOS (`aarch64-darwin`), ARM64 Linux
(`aarch64-linux`), and x86-64 Linux (`x86_64-linux`). Its layout follows
the [existing analysis templates](https://github.com/andrew2165/nix-flake-templates):
`supportedSystems`, `forAllSystems`, and per-system `let` blocks.
All executable code stays in this single flake; the README and lock file are
documentation and dependency metadata.


## Stable release build verification

On November 2, 2026, `nix build path:./outputs` succeeded on Apple Silicon macOS
using the stable `nixos-26.05` pin (R 4.5.3, MSstats 4.18.1,
MSstatsShiny 1.12.1). Runtime tests were not repeated for this pin.

## Previous Linux verification

These runtime checks used the earlier nixpkgs revision
`0bb2eedc20e4739f29e8045034f2828ad7054f8f`, before switching to stable
`nixos-26.05`. They have not been repeated against the stable pin.

Tested on November 2, 2026 in the ARM64 `docker.io/nixos/nix:latest` image
running under Podman (image digest
`sha256:5268ae74d0c4c9be8d10093fe85691564911f427f2b47530592c31aa9271458e`):

- `nix build` completed successfully.
- R 4.6.1 loaded MSstats 4.20.0 and MSstatsShiny 1.14.0.
- Every entry in R's `.libPaths()` was inside `/nix/store`.
- `nix flake check --no-build` passed for ARM64 Linux.
- MSstatsShiny started and returned HTTP 200 with the expected page.

The x86-64 Linux package output also evaluated successfully, but was not built
or run. These checks verify installation and startup, not a full data-analysis
workflow. The test container was stopped after verification.

For container use, bind Shiny to `0.0.0.0` **inside the container** with
`MSSTATS_HOST=0.0.0.0`, and publish its port to the host loopback address only
(e.g. Podman's `-p 127.0.0.1:3839:3838`). Outside a container the default
`127.0.0.1` binding is sufficient.
