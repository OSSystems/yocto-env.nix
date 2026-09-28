{
  description = "Yocto Project - Development Environment";

  inputs = {
    # Its glibc must stay within every supported release's uninative cap;
    # see doc/uninative-glibc-caps.md before moving it.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
