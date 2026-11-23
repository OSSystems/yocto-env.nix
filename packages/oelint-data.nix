{ lib, pkgs }:

let
  ps = pkgs.python3Packages;
  oelint-parser = import ./oelint-parser.nix { inherit lib pkgs; };
in
ps.buildPythonPackage (finalAttrs: {
  pname = "oelint-data";
  version = "1.6.1";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "priv-kweihmann";
    repo = "oelint-data";
    tag = finalAttrs.version;
    hash = "sha256-JSZNxXlFCkD08ZPo2781ZL+VVzxAfpUBlh+vw/jKLe0=";
  };

  build-system = [ ps.setuptools ];

  dependencies = [ oelint-parser ];

  pythonImportsCheck = [ "oelint_data" ];

  doCheck = false;

  meta = {
    description = "Data for oelint-adv";
    homepage = "https://github.com/priv-kweihmann/oelint-data";
    changelog = "https://github.com/priv-kweihmann/oelint-data/releases/tag/${finalAttrs.version}";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.linux;
  };
})
