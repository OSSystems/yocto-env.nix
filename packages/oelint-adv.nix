# Local oelint-adv package wired to the in-tree oelint-parser, so recipe
# linting tracks upstream releases without waiting on a nixpkgs bump. Bump the
# `version`/`hash` here (and in oelint-parser.nix) to roll forward.
{ pkgs, lib }:

let
  ps = pkgs.python3Packages;
  oelint-parser = import ./oelint-parser.nix { inherit pkgs lib; };
  # Rebuild oelint-data against our parser too, otherwise the nixpkgs
  # oelint-data drags in its own oelint-parser and the closure ends up with
  # two versions (pythonCatchConflictsPhase fails).
  oelint-data = ps.oelint-data.override { inherit oelint-parser; };
in
ps.buildPythonApplication (finalAttrs: {
  pname = "oelint-adv";
  version = "9.9.1";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "priv-kweihmann";
    repo = "oelint-adv";
    tag = finalAttrs.version;
    hash = "sha256-656OiHkRVP2M9/gR8faR2mEw9EzjHy92JRk82bD+I4k=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "--random-order-bucket=global" "" \
      --replace-fail "--random-order"               "" \
      --replace-fail "--force-sugar"                "" \
      --replace-fail "--old-summary"                ""
  '';

  build-system = [ ps.setuptools ];

  dependencies =
    (with ps; [
      anytree
      argcomplete
      colorama
      urllib3
    ])
    ++ [
      oelint-data
      oelint-parser
    ];

  nativeCheckInputs = with ps; [
    pytest-cov-stub
    pytest-forked
    pytest-xdist
    pytestCheckHook
  ];

  disabledTests = [
    # requires network access
    "TestClassOelintVarsHomepagePing"
  ];

  pythonRelaxDeps = [
    "argcomplete"
    "urllib3"
  ];

  pythonImportsCheck = [ "oelint_adv" ];

  meta = {
    description = "Advanced bitbake-recipe linter";
    mainProgram = "oelint-adv";
    homepage = "https://github.com/priv-kweihmann/oelint-adv";
    changelog = "https://github.com/priv-kweihmann/oelint-adv/releases/tag/${finalAttrs.version}";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.linux;
  };
})
