{ slimlock
, nodePackages
, python3
, pkg-config
, poppler_utils
, pangomm
, jq
}:
let
  packageLock = (slimlock.buildPackageLock {
    src = ./.;
  }).overrideAttrs (final: prev: {
    nativeBuildInputs = prev.nativeBuildInputs or [ ] ++ [
      nodePackages.node-pre-gyp
      python3
      pkg-config
      poppler_utils
      pangomm
      jq
    ];

    buildPhase = ''
      echo "Rebuilding node_modules with patched shebangs and install scripts..."

      rm ./node_modules/.bin/node-pre-gyp

      PACKAGES="$(\
        cat package-lock.json \
          | jq -r \
            '.packages 
              | keys_unsorted 
              | .[] 
              | select(length > 0 and . != "node_modules/@mapbox/node-pre-gyp") 
              | "./" + .' \
      )"

      npm rebuild --offline "$PACKAGES"
    '';
  });
in
packageLock
