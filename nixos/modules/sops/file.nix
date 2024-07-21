{ config, lib, ... }:
let
  hostName = config.networking.hostName;
  secretsDirectory = ../../../secrets;
in
{
  options.sops-file = with lib; mkOption { type = types.attrsOf types.path; };
  config = {
    sops-file.common = "${secretsDirectory}/all-hosts.yaml";
    sops-file.host = "${secretsDirectory}/hosts/${hostName}.yaml";

    # see Mic92/sops-nix#167 for setting up with impermanence
    sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    sops.gnupg.sshKeyPaths = [ ];
  };
}
