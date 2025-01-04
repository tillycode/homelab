{ config, lib, ... }:
let
  persistentStoragePath = config.environment.persistence.default.persistentStoragePath or null;
in
{
  # impermanence create parent directories with default permissions
  # this might not work under all circumstances
  # we can create the parent directories with the correct permissions
  system.activationScripts = lib.mkIf (persistentStoragePath != null) {
    fixCreatePersistentStorageDirs = {
      deps = [
        "users"
        "groups"
      ];
      text = ''
        mkdir -p --mode 0755 ${persistentStoragePath}/var
        mkdir -p --mode 0755 ${persistentStoragePath}/var/lib
        mkdir -p --mode 0700 ${persistentStoragePath}/var/lib/private
      '';
    };
    createPersistentStorageDirs.deps = [ "fixCreatePersistentStorageDirs" ];
  };

}
