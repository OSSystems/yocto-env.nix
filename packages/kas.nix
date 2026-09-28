# kas strips the dev-shell's Nix cc-wrapper environment
# (context.py:setup_initial_environ), leaving native binaries with a /nix/store
# glibc rpath that mismatches uninative's ld.so. The patches let the shell
# inject a config fragment, named by $KAS_NIXVARS_CONFIG, that restores it.
{ pkgs, ... }:

let
  version = "5.5";
in
pkgs.kas.overrideAttrs (old: {
  inherit version;
  src = pkgs.fetchFromGitHub {
    owner = "siemens";
    repo = "kas";
    tag = version;
    hash = "sha256-4yaOCu42pDoqAnx1TSAMPf5c/zaHTHuul2GMcC+WvVY=";
  };
  # The inherited nixpkgs dependency list predates kas requiring colorlog.
  propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.python3Packages.colorlog ];
  patches = (old.patches or [ ]) ++ [
    ./kas-patches/0001-inject-nixvars-config.patch
    ./kas-patches/0002-exempt-injected-configs.patch
  ];
})
