{ lib, ... }:
{
  options.domains = lib.mkOption {
    type = with lib.types; attrsOf str;
    default = { };
  };

  config = {
    domains = {
      zitadel = "login.szp15.com";
    };
  };
}
