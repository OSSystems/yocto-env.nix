# Working on the dev-shell

One dev-shell serves all supported releases. On a uninative cap roll, bump the
`nixpkgs` input and tag the prior commit — do not fork per-codename shells. See
[uninative-glibc-caps.md](uninative-glibc-caps.md) for the rationale.

- The `.env` is interactive-only: `nix build .#devShells.<sys>.default` fails at
  the `.env` step (so `result` can be stale), and `nix develop --command` / piped
  stdin do not enter the sandbox.
- Inspect the live environment with `nix print-dev-env` — its `shellHook` holds the
  real bwrap invocation and the current `*-fhsenv-rootfs` path.
- Verify a change by building the `*-fhsenv-rootfs` derivation directly.
- FHS `/usr/bin` tools come from `targetPkgs`. A tool a package omits from its own
  `bin/` (e.g. `gcc-ar`, `lz4c`) is symlinked in `extraBuildCommands` — which writes
  the rootfs mapped to `/usr` (not `extraInstallCommands`); mind the `/usr/lib ->
  /usr/lib64` usr-merge.
