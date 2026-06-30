# Local oelint-parser package, tracking the latest upstream release so the
# linter's parser can move ahead of the nixpkgs pin with a one-line bump here
# instead of waiting on a channel roll.
{ pkgs, lib }:

let
  ps = pkgs.python3Packages;
in
ps.buildPythonPackage (finalAttrs: {
  pname = "oelint-parser";
  version = "8.11.5";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "priv-kweihmann";
    repo = "oelint-parser";
    tag = finalAttrs.version;
    hash = "sha256-DwbpF1H5fY854YKqB/8ppg6gMS2VhMzoyY8yr/DsfBk=";
  };

  # Upstream pins `regex == <exact>`; relax it onto whatever nixpkgs ships.
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
