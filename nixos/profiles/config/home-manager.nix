{ inputs, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.sharedModules = [
    {
      imports = [
        inputs.vscode-server.homeModules.default
      ];
    }
  ];
}
