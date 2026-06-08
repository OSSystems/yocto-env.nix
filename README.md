# yocto-env.nix

A Nix flake that provides a reproducible, FHS-compatible build environment
for the [Yocto Project](https://www.yoctoproject.org/).

The flake exposes a single dev-shell that works against every currently
supported Yocto release. Today that's:

| Codename    | Yocto | Released         | Status                       |
|-------------|-------|------------------|------------------------------|
| (master)    | —     | rolling          | tracks current dev           |
| `wrynose`   | 6.0   | 14 May 2026      | **LTS** — until April 2030   |
| `scarthgap` | 5.0   | 29 April 2024    | **LTS** — until April 2028   |
| `kirkstone` | 4.0   | 25 April 2022    | LTS — ended April 2026       |

All four share the same `UNINATIVE_MAXGLIBCVERSION` regime, so one
`nixpkgs` pin (currently `nixos-unstable`, glibc 2.42) keeps the FHS
`/lib/ld-linux-x86-64.so.2` compatible with each release's uninative
tarball. See [doc/uninative-glibc-caps.md](doc/uninative-glibc-caps.md)
for the full rationale.

When the cap regime shifts — a new release branches with a lower cap, or
master bumps past what the current pin can satisfy — the flake's
`nixpkgs` input is rolled forward in a new commit and the previous
commit is tagged. Consumers needing the older shell check out the tag.
We deliberately do not carry parallel per-codename shells; the historical
overhead never paid off given that cap regimes change on a multi-year
cadence.

## Quick start

You can use the flake directly from GitHub without cloning it:

```sh
nix develop github:OSSystems/yocto-env.nix
```

If you have the repo checked out locally, `nix develop` works the same
way against the working tree.

For an older Yocto release whose uninative cap predates the current
`nixpkgs` pin, check out the tag captured before the most recent roll:

```sh
nix develop github:OSSystems/yocto-env.nix/<tag>
```

## What the shell provides

The shell is an FHS bubblewrap environment
(`buildFHSEnvBubblewrap`) preconfigured with the host tooling
`bitbake` expects: `gcc`, `gdb`, `git`, `git-lfs`, `gnumake`, `chrpath`,
`cpio`, `diffstat`, `python3`, `rpcsvc-proto`, `util-linux`, plus the
usual compression/archive utilities and a Yocto-aware set of fetcher and
testimage helpers.

The shell also wires the Nix toolchain into bitbake's hash-based
caching: it exports `BB_ENV_PASSTHROUGH_ADDITIONS` with the
`NIX_*`/dynamic-linker variables bitbake needs to forward to its
subprocesses, and sets `BBPOSTCONF` to a generated conf snippet so
those variables survive `BB_BASEHASH_IGNORE_VARS`.

A configured `zsh` (grml + fzf + eza) is launched as the interactive
shell, with history persisted to `~/.history-yocto-env`.

## Project setup tools

Both of the project-bootstrap tools used in the Yocto ecosystem are on
`PATH`, so you can lay out a fresh build directory from inside the shell
with whichever one your project uses:

- **`bitbake-setup`** — the Yocto Project's official bootstrap tool. It
  reads a JSON description of the layers and config snippets to use,
  clones them at pinned revisions, and creates a directory ready to
  build. Start with `bitbake-setup list` to see the available
  configurations, then `bitbake-setup init` to instantiate one. This
  flake packages it from BitBake `yocto-6.0` (2.18.0) — see
  `packages/bitbake-setup.nix`.
- **`kas`** — the established alternative (from nixpkgs). It reads a YAML
  project description, clones the referenced layers at pinned revisions,
  and drives bitbake: `kas build path/to/project.yml` (or `kas shell` to
  drop into a configured build environment).

## Repository layout

- `flake.nix` — minimal entry point; uses [phaer/red-tape](https://github.com/phaer/red-tape).
- `lib/default.nix` — exports `mkYoctoEnv`, the dev-shell builder.
- `devshells/default.nix` — the single devshell.
- `packages/bitbake-setup.nix` — the `bitbake-setup` package (auto-exported by red-tape).
- `doc/uninative-glibc-caps.md` — supported set, refresh script, and tag-on-roll strategy.
- `treefmt.nix` + `formatter.nix` — formatter wiring (`nix fmt`).
