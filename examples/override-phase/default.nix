{ slimlock
, nodePackages
, python3
, pkg-config
, poppler_utils
, pangomm
, lib
}:
let
  packageLock = (slimlock.buildPackageLock {
    src = ./.;
  }).overrideAttrs (final: prev: {
    nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [
      nodePackages.node-pre-gyp
      python3
      pkg-config
      poppler_utils
      pangomm
    ];

    buildPhase = ''
      echo "Rebuilding node_modules with patched shebangs and install scripts..."

      rm ./node_modules/.bin/node-pre-gyp

      PACKAGES="${
        lib.trivial.pipe "${prev.src}/package-lock.json" [
          builtins.readFile
          builtins.fromJSON
          (x: x.packages)
          builtins.attrNames
          (builtins.filter (x: x != "" && x != "node_modules/@mapbox/node-pre-gyp"))
          (builtins.map (lib.strings.removePrefix "node_modules/"))
          (lib.strings.concatStringsSep " ")
        ]
      }"

      npm rebuild --offline "$PACKAGES"
    '';
  });
in
packageLock
