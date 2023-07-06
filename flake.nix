{
  description = "Minimal Nix library for building package-lock.json files.";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/release-23.05"; };

  outputs = { self, nixpkgs, }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        });

    in {
      overlays.default = import ./lib/overlay.nix;

      # A warning-free top-level flake output suitable for running unit tests
      # via  e.g. `nix eval .#lib`.
      lib = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in pkgs.callPackage ./tests { });

      checks = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in pkgs.callPackages ./examples { });
    };
}
