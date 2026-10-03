{ lib, pkgs }:

let
  ps = pkgs.python3Packages;
in
ps.buildPythonPackage (finalAttrs: {
  pname = "oelint-parser";
  version = "8.13.2";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "priv-kweihmann";
    repo = "oelint-parser";
    tag = finalAttrs.version;
    hash = "sha256-+r6ksbIdLxflCFCmiCTQEuUY5J9TeRFaLVjPQ3O35gE=";
  };

  pythonRelaxDeps = [ "regex" ];

  build-system = [ ps.setuptools ];

  dependencies = with ps; [
    regex
    deprecated
  ];

  nativeCheckInputs = with ps; [
    pytest-cov-stub
    pytest-forked
    pytest-random-order
    pytestCheckHook
  ];

  pythonImportsCheck = [ "oelint_parser" ];

  meta = {
    description = "Alternative parser for bitbake recipes";
    homepage = "https://github.com/priv-kweihmann/oelint-parser";
    changelog = "https://github.com/priv-kweihmann/oelint-parser/releases/tag/${finalAttrs.version}";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.linux;
  };
})
