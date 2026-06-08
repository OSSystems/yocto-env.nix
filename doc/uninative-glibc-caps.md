# Uninative glibc caps

Yocto's `uninative.bbclass` refuses to use the `uninative` sstate-portability
tarball when the **host** `ldd --version` reports a glibc newer than the cap
declared in `meta/conf/distro/include/yocto-uninative.inc`
(variable `UNINATIVE_MAXGLIBCVERSION`). When the cap is exceeded, you see:

```
WARNING: Your host glibc verson (X) is newer than that in uninative (Y).
Disabling uninative so that sstate is not corrupted.
```

…and every sstate artefact becomes host-glibc-specific, which breaks sstate
sharing and slows down clean builds. This flake works around it by pinning
the FHS bubblewrap (and therefore the `/lib/ld-linux-x86-64.so.2` that `ldd`
reports) to a nixpkgs release whose glibc is at or below the cap.

## Strategy

A **single devshell** (`devShells.${system}.default`) serves every
currently supported Yocto release. Today that's kirkstone (4.0 LTS),
scarthgap (5.0 LTS), wrynose (6.0 LTS), and the moving master branch.
All four happen to share the same uninative cap regime, so one
`pkgsForInteractiveShell` pin covers them all.

When the cap regime changes (e.g. master bumps to require a glibc the
current pin can no longer satisfy, or a new release branches off with a
lower cap), we **tag the current commit and roll `nixpkgs` forward** in
a new commit. Consumers needing the older shell check out the tag.
This is simpler than maintaining N parallel shells, given that the cap
regimes have only ever changed across multi-year windows.

## Source of truth

For each Yocto branch:

```
https://raw.githubusercontent.com/openembedded/openembedded-core/<branch>/meta/conf/distro/include/yocto-uninative.inc
```

These values change over time as a branch backports newer uninative
tarballs. Numbers below captured **2026-05-16**.

| Codename     | Yocto | UNINATIVE_MAXGLIBCVERSION | uninative tarball |
|--------------|-------|---------------------------|-------------------|
| `kirkstone`  | 4.0   | 2.41                      | 4.7               |
| `scarthgap`  | 5.0   | 2.43                      | 5.1               |
| `wrynose`    | 6.0   | 2.43                      | 5.1               |
| `master`     | —     | 2.43                      | 5.1               |

## Why `nixos-unstable`

Every tagged nixpkgs branch up through `nixos-25.11` ships a
`libc.so.6` with an undefined reference to
`__nptl_change_stack_perm@GLIBC_PRIVATE`. The uninative tarball from
kirkstone onwards (4.7+) bundles an `ld-linux-x86-64.so.2` that no
longer exports the symbol, so loading any conftest aborts with a
symbol-lookup error and autoconf reports "cannot run C compiled
programs". `nixos-unstable` (glibc 2.42) is the first nixpkgs build to
drop the reference and stays under master's cap of 2.43. Move to the
next NixOS release branch once it ships with the same glibc.

## Refresh script

```sh
# Caps per supported Yocto branch:
for b in kirkstone scarthgap wrynose master; do
  printf '%-12s ' "$b"
  curl -sSL \
    "https://raw.githubusercontent.com/openembedded/openembedded-core/${b}/meta/conf/distro/include/yocto-uninative.inc" \
    | grep -E '^UNINATIVE_(MAXGLIBCVERSION|VERSION|URL)' \
    | tr '\n' ' '
  echo
done

# Current nixpkgs glibc:
curl -sSL \
  "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/pkgs/development/libraries/glibc/common.nix" \
  | grep -oE 'version = "[0-9.]+' | head -1
```

If the table drifts, update this file and `flake.nix`'s `nixpkgs`
pin, then `nix fmt` and `nix flake check`.

## On a nixpkgs roll: re-check the host dependencies

The devshell relies on `buildFHSEnvBubblewrap`'s base layer for some of
the Yocto [build-host requirements][sysreq] (gawk, tar, gzip, bzip2, xz,
coreutils, diffutils, findutils, sed, grep, glibc + locales); `lib/`
only adds what that base omits (acl, iputils, texinfo, the python3
modules, etc.). That base list is upstream's `baseTargetPaths` and can
change between pins, so when rolling `nixpkgs` forward, re-verify the
shell still covers the [Required Packages for the Build Host][sysreq].

[sysreq]: https://docs.yoctoproject.org/ref-manual/system-requirements.html
