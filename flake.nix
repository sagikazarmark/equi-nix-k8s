{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];

      flake = {
        nixosConfigurations = {
          # ADD YOUR MACHINE CONFIGURATIONS HERE
        };
      };

      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: rec {
        devenv.shells = {
          default = {
            packages = with pkgs; [
              metal-cli

              nixos-rebuild
              openssh

              jq
            ];

            env = {
              METAL_CONFIG = "${config.devenv.shells.default.env.DEVENV_STATE}/equinix/metal.yaml";

              KUBECONFIG = "${config.devenv.shells.default.env.DEVENV_STATE}/kube/config";
            };

            scripts = {
              deploy.exec = ''
                NIX_SSHOPTS='-o ControlPath=~/.ssh/control/%C -o ControlMaster=no' nixos-rebuild switch --fast --verbose --flake .#$1 --target-host $2 --build-host $2 --use-remote-sudo
              '';
            };

            dotenv.disableHint = true;

            # https://github.com/cachix/devenv/issues/528#issuecomment-1556108767
            containers = pkgs.lib.mkForce { };
          };
        };
      };
    };
}
