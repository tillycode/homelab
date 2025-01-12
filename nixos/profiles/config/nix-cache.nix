{ config, ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.svc.szp.io/default"
    ];
    trusted-public-keys = [
      "default:xmfbjleCtsq4S/39VqDwKhzVg8Afd2YM7rjWWYHUqqk="
    ];
    netrc-file = config.sops.templates."nix-netrc".path;
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  # atticd-atticadm make-token --sub nixos --pull default --validity 1y
  sops.secrets."cache/atticPullToken" = { };
  sops.templates."nix-netrc" = {
    content = ''
      machine cache.svc.szp.io
      password ${config.sops.placeholder."cache/atticPullToken"}
    '';
  };
}
