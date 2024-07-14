{ config, lib, ... }:
let
  hostName = config.networking.hostName;
  secretsDirectory = ../../../secrets;
in
{
  options.sops-file = with lib; mkOption { type = types.attrOf types.path; };
  config = {
    sops-file.common = "${secretsDirectory}/all-hosts.yaml";
    sops-file.host = "${secretsDirectory}/hosts/${hostName}.yaml";
  };
}
