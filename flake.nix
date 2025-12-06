{
  description = "Shared Operations Utilities for Homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      lib = let
        mkGenericBuildImage = import ./lib/build-image.nix;
        mkPushMultiArch = import ./lib/push-multi-arch.nix;
        mkPushInsecure = import ./lib/push-insecure.nix;
        mkDevPush = import ./lib/dev-push.nix;
      in
      {
        inherit mkGenericBuildImage mkPushMultiArch mkPushInsecure mkDevPush;

        # Helper to instantiate all utilities at once
        mkUtils = { pkgs, system ? pkgs.system, supportedSystems ? [ "x86_64-linux" "aarch64-linux" ] }: {
          build-image = mkGenericBuildImage { inherit pkgs; };
          push-multi-arch = mkPushMultiArch { inherit pkgs supportedSystems; };
          push-insecure = mkPushInsecure { inherit pkgs system; };
          dev-push = mkDevPush { inherit pkgs; };
        };

        # Helper to generate apps for all utils
        mkApps = { pkgs }: utils:
          pkgs.lib.mapAttrs (name: pkg: {
            type = "app";
            program = "${pkg}/bin/${name}";
          }) utils;
      };

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nixpkgs-fmt
              pkgs.rnix-lsp
            ];
          };
        }
      );
    };
}