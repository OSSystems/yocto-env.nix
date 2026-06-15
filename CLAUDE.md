# yocto-env.nix

A single FHS dev-shell (`buildFHSEnvBubblewrap`) for Yocto builds. All the real
logic lives in `lib/default.nix`'s `mkYoctoEnv`; `devshells/default.nix` just
instantiates it.

`nix fmt` (nixfmt + statix via treefmt-nix) must leave the tree clean before a commit.

## Layout

- `flake.nix` — entry point, built on [phaer/red-tape](https://github.com/phaer/red-tape).
- `lib/default.nix` — `mkYoctoEnv`, the dev-shell builder.
- `doc/working-on-the-dev-shell.md` — how to inspect, build, and verify the dev-shell.
- `doc/uninative-glibc-caps.md` — the nixpkgs-pin / glibc-cap / tag-on-roll rationale.
- `treefmt.nix` + `formatter.nix` — formatter wiring.

## Working on the dev-shell

When modifying the dev-shell, read [doc/working-on-the-dev-shell.md](doc/working-on-the-dev-shell.md)
— the `.env` is interactive-only, so the usual `nix build` / `nix develop --command`
workflows don't apply.
