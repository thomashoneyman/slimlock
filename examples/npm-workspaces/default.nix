{
  stdenv,
  slimlock,
}: let
  packageLock = slimlock.buildPackageLock {
    src = ./.;
    omit = ["dev" "peer"];
  };
in
  stdenv.mkDerivation {
    name = "npm-workspaces";
    src = ./.;
    installPhase = ''
      cp -r ${packageLock}/js/node_modules $out
    '';
  }
