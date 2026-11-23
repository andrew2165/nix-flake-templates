# MSstats Affinity Profiling

This flake follows the [MSstatsShiny analysis template](https://github.com/andrew2165/nix-flake-templates/tree/11ea872765d017e822ab66595652ab184f036ca1/msstatsshiny). It keeps the template's stable nixpkgs 26.05 lock and adds three GitHub source inputs pinned to full commits.

| R package | GitHub commit |
| --- | --- |
| MSstatsAP | `757cde8bb22d5c37356a1aa52bc48c69b929211a` |
| MSstatsTMTAP | `b9a30b12c4f951f805496e2b43661b7872f0b801` |
| MSstatsShinyAP | `fdbaca4f54bd1ce174b216e1a21784dcf1739351` |

MSstatsBioNet 1.4.1 and MSstatsResponse 1.2.0 come from Bioconductor 3.23 with fixed source hashes. They supply APIs that MSstatsShinyAP imports. R and the remaining dependencies come from the template's nixpkgs pin.

## Launch the app

From this directory, run:

```sh
nix run path:.
```

Shiny opens the default browser at <http://127.0.0.1:3838>. Keep the terminal open while using the app. Press Ctrl-C to stop it. If the port is busy, use `MSSTATS_PORT=3839 nix run path:.`. For a headless launch, use `MSSTATS_OPEN_BROWSER=0 nix run path:.`.

Use `nix develop path:.` for an analysis shell with `R`, `Rscript`, and `msstats-shiny`. In that shell, run `msstats-shiny` whenever you want to start the app. The working directory is available for analysis data and outputs.

Run a script from outside the shell with `nix run path:.#rscript -- --vanilla analysis.R`. To inspect the installed fork versions, paths, and source commits in a fresh R session, run:

```sh
nix run path:.#rscript -- --vanilla -e '
for (pkg in c("MSstatsAP", "MSstatsTMTAP", "MSstatsShinyAP")) {
  cat(pkg, as.character(packageVersion(pkg)), find.package(pkg),
      packageDescription(pkg)$RemoteSha, "\n")
}'
```

The flake declares outputs for Apple Silicon macOS, ARM64 Linux, and x86-64 Linux. Keep `flake.nix` and `flake.lock` together when copying this environment into an analysis project. To change a fork pin, update its commit URL in `flake.nix`, then run `nix flake lock path:.`.

## Verification

On Apple Silicon macOS, the launcher and development shell passed with R 4.5.3. The local server returned HTTP 200, and a test browser command received the expected URL. R reported the three locked source SHAs from their installed Nix store paths. All 1,326 assertions across the three fork suites passed.

The synthetic FragPipe fixture passed through the package and Shiny summarization paths. Median and msstats each matched 48 ratios, with treatment-minus-control log2 fold changes of 0 and +1. Shiny produced the bait QC plot before normalization. The default policy raised the expected missing-bait error, and explicit drop removed exactly two client rows.

Linux outputs passed Nix evaluation. Runtime validation used the synthetic fixture and a test browser command on macOS.
