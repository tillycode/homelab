{ config, ... }:
let
  region = "cn-hangzhou";
  bucket = "szpio-restic-backups";
  endpoint = "https://oss-${region}.aliyuncs.com";
in
{
  services.restic.backups.default = {
    repository = "s3:${endpoint}/${bucket}";
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 75"
    ];
    extraOptions = [
      "s3.bucket-lookup=dns"
      "s3.region=${region}"
    ];
    environmentFile = config.sops.templates."restic/config.env".path;
    passwordFile = config.sops.secrets."restic/password".path;
  };

  sops.secrets."restic/awsAccessKeyId" = { };
  sops.secrets."restic/awsSecretAccessKey" = { };
  sops.secrets."restic/password" = { };
  sops.templates."restic/config.env" = {
    content = ''
      AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/awsAccessKeyId"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/awsSecretAccessKey"}
    '';
  };
}
