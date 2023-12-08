# Slimlock

[![nix-tests](https://github.com/thomashoneyman/slimlock/actions/workflows/test.yml/badge.svg)](https://github.com/thomashoneyman/slimlock/actions/workflows/test.yml)

A minimal Nix library for package-lock.json files.

## Installation

You can get `slimlock` with Nix flakes by adding it to your flake inputs and using the provided overlay in `slimlock.overlays.default`, which will insert the `slimlock` attribute into your packages:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";

    slimlock.url = "github:thomashoneyman/slimlock";
    slimlock.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, slimlock }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ slimlock.overlays.default ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in {
        # You now have slimlock in your pkgs.

      });
}
```

## Usage

All packages in the `package-lock.json` file must have integrity fields of the form `"integrity": "sha512-..."` . NPM is not strict about this, so packages can sometimes be missing hashes. In this case, recreate the `package-lock.json` file:

```console
rm package-lock.json
rm -rf node_modules
npm cache clear --force
npm install
```

With `slimlock` installed, you can write a derivation to build `node_modules` and `bin` directories from a `package-lock.json` file. For example, this derivation relies on a `package-lock.json` file present in `src`:

```nix
{ slimlock, stdenv }: stdenv.mkDerivation rec {
  name = "my-package";
  src = ./my-package;
  modules = slimlock.buildPackageLock { inherit src };
  buildPhase = ''
    ln -s ${modules}/js/node_modules .
  '';
}
```

You can override a slimlock derivation if, for example, you have dependencies that require native build dependencies. See examples:

- [override-attrs](./examples/override-attrs/default.nix)
- [override-phase](./examples/override-phase/default.nix)

Phases are documented [here](https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases).
