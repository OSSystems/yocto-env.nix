{ lib, pkgs }:

let
  ps = pkgs.python3Packages;
in
ps.buildPythonApplication (finalAttrs: {
  pname = "bitbake-setup";
  version = "2.19.0";
  format = "wheel";

  src = ps.fetchPypi {
    inherit (finalAttrs) version;
    pname = "bitbake_setup";
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-tq53r8I02HL4mTgnIxcVf4VTYhRngYgl232/cDgLzdI=";
  };

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        pkgs.git
        pkgs.diffutils
      ]
    }"
  ];

  pythonImportsCheck = [ "bitbake_setup" ];

  meta = {
    description = "Yocto Project BitBake environment bootstrap tool (bitbake-setup)";
    homepage = "https://git.openembedded.org/bitbake/";
    changelog = "https://pypi.org/project/bitbake-setup/${finalAttrs.version}/";
    license = lib.licenses.gpl2Only;
    mainProgram = "bitbake-setup";
    platforms = lib.platforms.linux;
  };
})
