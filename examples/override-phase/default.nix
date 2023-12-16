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

    # `runHook` is used to let downstream users run `preBuild` and `postBuild` hooks
    # see https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases

    # `./`-prefixed packages are used due to `package-spec` for folders
    # https://docs.npmjs.com/cli/v10/using-npm/package-spec#folders
    buildPhase = ''
      runHook preBuild

      echo "Rebuilding node_modules with patched shebangs and install scripts..."

      rm ./node_modules/.bin/node-pre-gyp

      PACKAGES="${
        lib.trivial.pipe "${prev.src}/package-lock.json" [
          builtins.readFile
          builtins.fromJSON
          (x: x.packages)
          builtins.attrNames
          (builtins.filter (x: x != "" && x != "node_modules/@mapbox/node-pre-gyp"))
          (lib.strings.concatMapStringsSep " " (x: "./${x}"))
        ]
      }"

      npm rebuild --offline "$PACKAGES"

      runHook postBuild
    '';
  });
in
packageLock
