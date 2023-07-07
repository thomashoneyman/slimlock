{
  stdenv,
  slimlock,
  nodejs,
  python3,
  nodePackages,
  esbuild,
}: let
  packageLock = (slimlock.buildPackageLock {src = ./.;}).overrideAttrs (final: prev: {
    nativeBuildInputs = prev.nativeBuildInputs or [] ++ [python3 nodePackages.node-gyp];
  });
in
  stdenv.mkDerivation rec {
    name = "override-attrs";
    src = ./.;
    installPhase = ''
      mkdir -p $out/bin
      cp $src/package.json $out/package.json
      cp -r ${packageLock}/js/node_modules $out/node_modules
      cp $src/entrypoint.js $out/entrypoint.js
      echo '#!/usr/bin/env sh' > $out/bin/${name}
      echo 'exec ${nodejs}/bin/node '"$out/entrypoint.js"' "$@"' >> $out/bin/${name}
      chmod +x $out/bin/${name}
    '';
  }
