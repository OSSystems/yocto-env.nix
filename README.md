# yocto-env.nix

A Nix flake that provides a reproducible, FHS-compatible build environment
for the [Yocto Project](https://www.yoctoproject.org/).

The flake exposes a single dev-shell that works against every currently
supported Yocto release. Today that's:

| Codename    | Yocto | Released         | Status                       |
|-------------|-------|------------------|------------------------------|
| (master)    | -     | rolling          | tracks current dev           |
| `wrynose`   | 6.0   | 14 May 2026      | **LTS**, until April 2030    |
| `scarthgap` | 5.0   | 29 April 2024    | **LTS**, until April 2028    |

All three have a `UNINATIVE_MAXGLIBCVERSION` of at least 2.43, so one
`nixpkgs` pin (currently `nixos-26.05`, glibc 2.42) keeps the FHS
`/lib/ld-linux-x86-64.so.2` compatible with each release's uninative
tarball. See [doc/uninative-glibc-caps.md](doc/uninative-glibc-caps.md)
for the full rationale.

When a release loses support here (it reaches end of life, or the cap
regime shifts so the current pin can no longer satisfy it), the commit
before the change is kept on a branch named after that release, and the
change lands in a new commit on `master`. We deliberately do not carry
parallel per-codename shells on `master`; the historical overhead never
paid off given that cap regimes change on a multi-year cadence.

## Quick start

You can use the flake directly from GitHub without cloning it:

```sh
nix develop github:OSSystems/yocto-env.nix
```

If you have the repo checked out locally, `nix develop` works the same
way against the working tree.

For a Yocto release no longer supported here, use the branch named
after it. Today that's `kirkstone` (4.0):

```sh
nix develop github:OSSystems/yocto-env.nix/kirkstone
```

## What the shell provides

The shell is an FHS bubblewrap environment
(`buildFHSEnvBubblewrap`) preconfigured with the host tooling
`bitbake` expects: `gcc` (including the `gcc-ar`/`gcc-nm`/`gcc-ranlib`
LTO wrappers that LTO-enabled recipes such as `u-boot-tools-native`
require), `gdb`, `git`, `git-lfs`, `gnumake`, `chrpath`, `cpio`,
`diffstat`, `python3`, `rpcsvc-proto`, `util-linux`, plus the usual
compression/archive utilities and a Yocto-aware set of fetcher and
testimage helpers.

The shell also wires the Nix toolchain into bitbake: it sets
`BBPOSTCONF` (and, for kas, `KAS_NIXVARS_CONFIG`) to a generated conf
snippet that exports fixed values for the `NIX_*` compiler-wrapper
variables and `LOCALE_ARCHIVE` to every task and lists them in
`BB_BASEHASH_IGNORE_VARS`, so they don't change task hashes or sstate
reuse.

A configured `zsh` (grml + fzf + eza) is launched as the interactive
shell, with history persisted to `~/.history-yocto-env`.

## Project setup tools

The project-bootstrap tools used in the Yocto ecosystem are on `PATH`, so
you can lay out a fresh build directory from inside the shell with
whichever one your project uses:

- **`bitbake-setup`**: the Yocto Project's official bootstrap tool. It
  reads a JSON description of the layers and config snippets to use,
  clones them at pinned revisions, and creates a directory ready to
  build. Start with `bitbake-setup list` to see the available
  configurations, then `bitbake-setup init` to instantiate one.
- **`kas`**: the established alternative. It reads a YAML project
  description, clones the referenced layers at pinned revisions, and
  drives bitbake: `kas build path/to/project.yml` (or `kas shell` to drop
  into a configured build environment).
- **`repo`**: Google's multi-repository tool. Vendor BSPs that ship a
  manifest use it: `repo init -u <manifest-url> -b <branch>` followed by
  `repo sync` lays out the tree.

`oelint-adv`, an advanced bitbake-recipe linter, is also on `PATH` for
checking recipe style and common mistakes: `oelint-adv path/to/recipe.bb`.
