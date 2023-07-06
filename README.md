# Slimlock

[![nix-tests](https://github.com/thomashoneyman/slimlock/actions/workflows/test.yml/badge.svg)](https://github.com/thomashoneyman/slimlock/actions/workflows/test.yml)

A minimal Nix library for package-lock.json files.

## Installation

You can get `slimlock` with Nix flakes by adding it to your flake inputs and using the provided overlay in `slimlock.overlays.default`, which will insert the `slimlock` attribute into your packages:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    slimlock.url = "github:thomashoneyman/slimlock";
    slimlock.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, slimlock }:
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

With `slimlock` installed, you can write a derivations to build a `node_modules` and `bin` directory from a `package-lock.json` file. For example, this derivation relies on a `package-lock.json` file present in `src`:

```nix
{ slimlock, stdenv }: stdenv.mkDerivation rec {
  name = "my-package";
  src = ./my-package;
  modules = slimlock.buildPackageLock { inherit src };
  buildPhase = ''
    ln -s ${modules}/node_modules .
  '';
}
```
