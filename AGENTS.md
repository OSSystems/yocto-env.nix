# yocto-env.nix

A Nix flake providing one FHS dev-shell (`buildFHSEnvBubblewrap`, built by `mkYoctoEnv` in
`lib/default.nix`) for every supported Yocto release, plus a plain `lint` shell that runs
`oelint-adv` non-interactively.

`nix fmt` (pedantix + statix via treefmt-nix) must leave the tree clean before a commit.

Punctuate prose (docs, comments, commit messages) with commas, colons, semicolons, or parentheses;
the em dash (—) is not used.

## Supporting docs

- [doc/working-on-the-dev-shell.md](doc/working-on-the-dev-shell.md): read before changing the
  dev-shell; its `.env` is interactive-only, so `nix build` and `nix develop --command` can't
  exercise it.
- [doc/uninative-glibc-caps.md](doc/uninative-glibc-caps.md): read before changing the `nixpkgs`
  pin, the GCC version, or the supported Yocto releases.

## Coding standards

### Comments

Keep only **load-bearing** comments: the reason for a choice, a constraint that
no type expresses, or the legacy behaviour that the code must match.

When you touch a line, delete the comment on it that only restates the code, in
the same edit.

Put history in the commit message or the pull request, not in a comment: the
version that failed, the run that broke, the issue that caused the change.
