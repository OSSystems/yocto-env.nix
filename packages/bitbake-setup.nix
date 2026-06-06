# bitbake-setup imports bb.* from its sibling lib/, so install the whole
# BitBake tree and expose only that entry point.
{ pkgs, lib }:

pkgs.stdenv.mkDerivation {
  pname = "bitbake-setup";
  version = "2.18.0";

  src = pkgs.fetchFromGitHub {
    owner = "openembedded";
    repo = "bitbake";
    rev = "yocto-6.0";
    hash = "sha256-RyMss2lWM04eFanbZNerlgRE971q7yKxQjPuN02D2IU=";
  };

  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.python3
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/bitbake"
    cp -r bin lib "$out/share/bitbake/"
    patchShebangs "$out/share/bitbake/bin"

    makeWrapper "$out/share/bitbake/bin/bitbake-setup" "$out/bin/bitbake-setup" \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.git
          pkgs.diffutils
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Yocto Project BitBake environment bootstrap tool (bitbake-setup)";
    homepage = "https://git.openembedded.org/bitbake/";
    license = lib.licenses.gpl2Only;
    mainProgram = "bitbake-setup";
    platforms = lib.platforms.linux;
  };
}
