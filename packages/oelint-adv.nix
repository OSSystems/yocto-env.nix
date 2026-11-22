{ lib, pkgs }:

let
  ps = pkgs.python3Packages;
  oelint-parser = import ./oelint-parser.nix { inherit lib pkgs; };
  oelint-data = import ./oelint-data.nix { inherit lib pkgs; };
in
ps.buildPythonApplication (finalAttrs: {
  pname = "oelint-adv";
  version = "9.14.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "priv-kweihmann";
    repo = "oelint-adv";
    tag = finalAttrs.version;
    hash = "sha256-5D0TAFXN6A/1xxnESW7c1qHi5QvQ9QZjJbPWuw+wwjQ=";
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

  disabledTests = [ "TestClassOelintVarsHomepagePing" ];

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
