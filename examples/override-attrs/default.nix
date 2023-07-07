{
  stdenv,
  slimlock,
  nodejs,
  python3,
  nodePackages,
}: let
  packageLock = (slimlock.buildPackageLock {src = ./.;}).overrideAttrs (final: prev: {
    nativeBuildInputs = prev.nativeBuildInputs or [] ++ [python3 nodePackages.node-gyp];
    configurePhase = ''
      export npm_config_nodedir="${nodejs}"
    '';
  });
in
  stdenv.mkDerivation {
    name = "node-gyp-example";
    src = ./.;
    installPhase = ''
      cp -r ${packageLock}/js/node_modules $out
    '';
  }
