{
  description = "Yocto Project - Development Environment";

  inputs = {
    # Single nixpkgs source for every supported devshell. `nixos-26.05`
    # is the first release branch whose `libc.so.6` drops the undefined
    # `__nptl_change_stack_perm@GLIBC_PRIVATE` reference that breaks the
    # uninative tarball shipped from kirkstone onwards (4.7+). See
    # doc/uninative-glibc-caps.md.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Host Python for the build shell. Kept on an older release branch,
    # separate from the `nixpkgs` pin above, because 26.05's python311
    # package set fails to evaluate (gitpython and google-cloud-storage
    # pull sphinx 9.1.0 via build/test dependencies, which nixpkgs marks
    # unsupported on 3.11). python311 is required for kirkstone, whose
    # sanity check imports stdlib `distutils` (gone in 3.12+). The Python
    # interpreter's glibc is unrelated to the uninative caps issue that
    # dictates the `nixpkgs` pin, so mixing is safe here.
    nixpkgs-python.url = "github:NixOS/nixpkgs/nixos-25.05";
    red-tape = {
      url = "github:phaer/red-tape";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pedantix = {
      url = "github:Swarsel/pedantix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      base = inputs.red-tape.mkFlake {
        inherit inputs self;
        src = ./.;
        systems = [ "x86_64-linux" ];
      };
    in
    base
    // {
      # red-tape auto-promotes every devShell into `checks.<system>.devshell-<name>`,
      # but FHS bubblewrap envs refuse to be built outside `nix develop`
      # ("User chroot 'env' attributes are intended for interactive
      # nix-shell sessions, not for building!"). Swap the check for the
      # shell's `inputDerivation`, which builds every package the shell
      # pulls in without invoking bubblewrap, enough to catch eval and
      # closure regressions in `nix flake check`.
      checks = base.checks // {
        x86_64-linux = base.checks.x86_64-linux // {
          devshell-default = base.devShells.x86_64-linux.default.inputDerivation;
        };
      };
    };
}
