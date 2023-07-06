{ pkgs }:
let
  overlay = import ./lib/overlay.nix;
  final = pkgs.extend overlay;
in final.slimlock // { pkgs = final; }
