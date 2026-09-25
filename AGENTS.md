# yocto-env.nix

A Nix flake providing one FHS dev-shell (`buildFHSEnvBubblewrap`, built by `mkYoctoEnv` in
`lib/default.nix`) for every supported Yocto release, plus a plain `lint` shell that runs
`oelint-adv` non-interactively.

`nix fmt` (pedantix + statix via treefmt-nix) must leave the tree clean before a commit.

Comments record only a non-obvious constraint or workaround a reader can't deduce from the code.
Other rationale goes in the commit message.

Punctuate prose (docs, comments, commit messages) with commas, colons, semicolons, or parentheses;
the em dash (—) is not used.

## Supporting docs

- [doc/working-on-the-dev-shell.md](doc/working-on-the-dev-shell.md): read before changing the
  dev-shell; its `.env` is interactive-only, so `nix build` and `nix develop --command` can't
  exercise it.
- [doc/uninative-glibc-caps.md](doc/uninative-glibc-caps.md): read before changing the `nixpkgs`
  pin, the GCC version, or the supported Yocto releases.
