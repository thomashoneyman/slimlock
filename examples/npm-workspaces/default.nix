{ stdenv, slimlock, }:
let packageLock = slimlock.buildPackageLock { src = ./.; };
in stdenv.mkDerivation {
  name = "npm-workspaces";
  src = ./.;
  installPhase = ''
    cp -r ${packageLock}/node_modules $out
  '';
}
