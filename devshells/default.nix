{ pkgs, flake, ... }:

# See doc/uninative-glibc-caps.md for the supported Yocto releases and
# the tag-on-roll strategy used when the nixpkgs pin changes.
flake.lib.mkYoctoEnv pkgs
