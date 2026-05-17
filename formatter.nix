{ pkgs, inputs, ... }:

inputs.treefmt-nix.lib.mkWrapper pkgs ./treefmt.nix
