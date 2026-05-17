# Repository conventions

## Formatting

Always run `nix fmt` before committing anything. It runs `nixfmt` (and
`statix`) through `treefmt-nix` over every Nix file in the tree and the
commit is expected to be clean afterwards.

```sh
nix fmt
git add -p
git commit
```

If a hook or reviewer flags an unformatted file, re-run `nix fmt` and amend
or follow up with a new commit rather than hand-editing whitespace.

## Layout

- `flake.nix` — minimal entry point; uses [phaer/red-tape](https://github.com/phaer/red-tape).
- `lib/default.nix` — exports `mkYoctoEnv`, the dev-shell builder.
- `devshells/default.nix` — the single devshell. When the uninative cap
  regime forces a nixpkgs roll, tag the current commit so consumers of
  older Yocto releases can check it out; we do not carry parallel
  codename shells.
- `doc/uninative-glibc-caps.md` — supported set + tagging strategy.
- `treefmt.nix` + `formatter.nix` — formatter wiring.
