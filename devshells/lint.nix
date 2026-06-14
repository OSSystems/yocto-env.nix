{ pkgs, flake, ... }:

# Non-FHS shell for linting recipes non-interactively (e.g. in CI), where the
# default bwrap shell can't be entered via `nix develop --command`.
pkgs.mkShellNoCC {
  packages = [ flake.packages.${pkgs.system}.oelint-adv ];
}
