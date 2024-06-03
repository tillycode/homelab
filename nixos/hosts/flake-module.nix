{ inputs, ... }:
{
  flake.nixosConfigurations.aliyun-hz2 = inputs.nixpkgs.lib.nixosSystem {
    modules = [ ./aliyun-hz2 ];
    specialArgs = {
      inherit inputs;
    };
    system = "x86_64-linux";
  };
}
