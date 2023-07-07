{
  lib,
  fetchurl,
  writeTextFile,
  nodejs,
  stdenv,
}: rec {
  # Read a package-lock.json as a Nix attrset
  readPackageLock = lockfile: builtins.fromJSON (builtins.readFile lockfile);

  # Read the dependencies listed in a package-lock.json file where each key is
  # the name of a dependency and each value is an attrset with the following
  # keys:
  #   - version: The version of the dependency
  #   - integrity: The sri hash of the dependency
  #   - resolved: The URL of the tarball for the dependency from the NPM registry
  getDependencies = lock: let
    rootWorkspace = "";
    workspaceDirs = lock.packages.${rootWorkspace}."workspaces" or [];
    workspaceNodeModuleDirs = builtins.map (dir: "node_modules/" + dir) workspaceDirs;
    workspaceNames = builtins.map (dir: "node_modules/" + lock.packages.${dir}.name or dir) workspaceDirs;

    allWorkspaces = lib.unique ([rootWorkspace] ++ workspaceDirs ++ workspaceNames ++ workspaceNodeModuleDirs);
    removeWorkspaces = packages: removeAttrs packages allWorkspaces;

    verifyPackage = name: value: {
      version = value.version or (throw "Dependency ${name} does not have a 'version' key");
      integrity = value.integrity or (throw "Dependency ${name} does not have an 'integrity' key");
      resolved = value.resolved or (throw "Dependency ${name} does not have a 'resolved' key");
    };

    # NPM lockfiles differ depending on their version. v1 lockfiles used a
    # "dependencies" key, while v2 lockfiles use a "packages" key.
    allDependencies = lock.packages or lock.dependencies or {};
  in
    lib.mapAttrs verifyPackage (removeWorkspaces allDependencies);

  # Turn each dependency into a fetchurl call. At the moment, this code does not
  # support any other type of dependency; for that, see other NPM lockfile
  # libraries like npmlock2nix.
  fetchDependencyTarball = name: dependency:
    fetchurl {
      name = let version = dependency.version or (throw "Dependency ${name} does not have a 'version' key"); in "${name}-${version}.tgz";
      url = dependency.resolved or (throw "Dependency ${name} does not have a 'resolved' key");
      hash = dependency.integrity or (throw "Dependency ${name} does not have an 'integrity' key");
    };

  # https://docs.npmjs.com/cli/v8/commands/npm-ci#omit
  omitCmd = omit:
    if builtins.any (x: x != omit) ["prod" "dev" "peer"]
    then lib.concatStringsSep " " (builtins.map (x: "--omit=" + x) omit)
    else throw "Can only omit 'prod', 'dev', and/or 'peer' dependencies.";

  auditCmd = audit:
    if audit
    then "--audit"
    else "--no-audit";

  # Build a package from a package-lock.json file. This will fetch all the
  # tarballs for the dependencies listed in the lockfile and then run `npm ci`
  buildPackageLock = {
    src,
    omit ? [],
    audit ? false,
  }: let
    lockfile = src + "/package-lock.json";
    packageLock = readPackageLock lockfile;

    # Fetch all the tarballs for the dependencies
    dependencies = getDependencies packageLock;
    tarballs = builtins.attrValues (builtins.mapAttrs fetchDependencyTarball dependencies);

    # Write a file with the list of tarballs
    tarballsFile = writeTextFile {
      name = "tarballs";
      text = (builtins.concatStringsSep "\n" tarballs) + "\n";
    };
  in
    stdenv.mkDerivation {
      name = packageLock.name;
      version = packageLock.version or "0.0.0";

      # We only want to include the package.json and package-lock.json to avoid
      # unnecessary rebuilds.
      src = lib.cleanSourceWith {
        filter = name: _:
          !(builtins.elem name ["package.json" "package-lock.json"]);
        src = lib.cleanSource src;
      };

      propagatedBuildInputs = [nodejs];

      buildPhase = ''
        export HOME=$PWD/.home
        export npm_config_cache=$PWD/.npm
        export npm_config_jobs="max"
        export npm_config_nodedir="${nodejs}"

        mkdir -p $out/js
        cd $out/js
        cp -r $src/. .
        cat ${tarballsFile} | xargs npm cache add
        npm ci ${omitCmd omit} ${auditCmd audit} --ignore-scripts
        test -d node_modules/.bin && patchShebangs node_modules/.bin
        echo "Rebuilding node_modules with patched shebangs and install scripts..."
        npm rebuild --offline
      '';

      installPhase = ''
        ln -s $out/node_modules/js/.bin $out/bin
      '';
    };
}
