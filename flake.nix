{
  description = "Yocto Project - Development Environment";

  inputs = {
    # Single nixpkgs source for every supported devshell. Tracks
    # `nixos-unstable` because the uninative tarball shipped from
    # kirkstone onwards (4.7+) requires a `libc.so.6` without the
    # undefined `__nptl_change_stack_perm@GLIBC_PRIVATE` reference, and
    # every tagged branch up through `nixos-25.11` still carries it.
    # Swap to the next NixOS release branch once it ships a clean
    # libc. See doc/uninative-glibc-caps.md.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    red-tape.url = "github:phaer/red-tape";
    red-tape.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, ... }@inputs:
    let
      base = inputs.red-tape.mkFlake {
        inherit self inputs;
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
      # pulls in without invoking bubblewrap — enough to catch eval and
      # closure regressions in `nix flake check`.
      checks = base.checks // {
        x86_64-linux = base.checks.x86_64-linux // {
          devshell-default = base.devShells.x86_64-linux.default.inputDerivation;
        };
      };
    };
}
