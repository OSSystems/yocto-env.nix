# kas patched to inherit the dev-shell's Nix cc-wrapper environment, which kas
# otherwise strips (context.py:setup_initial_environ), leaving native binaries
# with a /nix/store glibc rpath that mismatches uninative's ld.so and aborts
# ("stack smashing detected"). 0001 lets the shell inject a fragment named by
# $KAS_NIXVARS_CONFIG that restores it; 0002 exempts that injected fragment from
# the "same repo" guard so it can coexist with in-repo configs.
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
  # 5.5 makes colorlog mandatory. nixpkgs still packages 5.3, so the dependency
  # list we inherit lacks it and pythonRuntimeDepsCheckHook rejects the wheel.
  propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.python3Packages.colorlog ];
  patches = (old.patches or [ ]) ++ [
    ./kas-patches/0001-inject-nixvars-config.patch
    ./kas-patches/0002-exempt-injected-configs.patch
  ];
})
