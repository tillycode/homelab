{ pkgs, lib, ... }:
let
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  port = 25565;
  root = ./_minecraft-modpack;
  modpack = pkgs.fetchLocalPackwizModpack {
    packHash = "sha256-4zacJ+rEqF3DZM6yyf4gINUV51r8FQCzS5iwqEZiZsU=";
    inherit root;
  };

  mcVersion = modpack.manifest.versions.minecraft;
  fabricVersion = modpack.manifest.versions.fabric;
  serverVersion = lib.replaceStrings [ "." ] [ "_" ] "fabric-${mcVersion}";
in
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    servers.default = {
      enable = true;
      package = pkgs.fabricServers.${serverVersion}.override { loaderVersion = fabricVersion; };
      serverProperties = {
        difficulty = "hard";
        gamemode = "survival";
        motd = ''\u00A7e\u00A7oZiping Sun's\u00A7r Minecraft Server\u00A7r\n\u00A72\u00A7lHappy \u00A7kCrafting!'';
        white-list = true;
      };
      whitelist = {
        sunziping2016 = "78b7406b-834b-42a7-948a-0a8087b6932e";
        aaaaaaaqie = "fc50c689-79e1-46d1-87b0-63b7234eacb7";
        Forev3rNAlway5 = "cc64d967-bf1f-43a8-bbee-2eaaf4b332e5";
        list17 = "270bac35-7951-4830-8640-5b7fac19e9f5";
      };
      symlinks = {
        "mods" = "${modpack}/mods";
        "dynmap/configuration.txt" = "${root}/dynmap/configuration.txt";
      };
    };
  };

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall.allowedTCPPorts = [ port ];

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/src/minecraft";
      user = "minecraft";
      group = "minecraft";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## BACKUP
  ## ---------------------------------------------------------------------------
  services.restic.backups.default.paths = [
    "/srv/minecraft/default/world"
  ];
}
