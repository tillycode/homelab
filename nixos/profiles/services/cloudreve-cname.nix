{
  config,
  pkgs,
  lib,
  ...
}:
let
  ramRole = "cloudreve-cname-certificate";
  aliyunRegion = "cn-hangzhou";
  aliyunRamRoleName = "cloudreve-cname-certificate";
  domain = config.domains.cloudreve-cname;
  bucketName = "szpio-cloudreve-storage";
  cert = config.security.acme.certs.${domain};
in
{

  security.acme.certs.${domain} = {
    dnsProvider = "alidns";
    environmentFile = pkgs.writeText "alidns.env" ''
      ALICLOUD_RAM_ROLE=${ramRole}
    '';
    group = "cloudreve-cname";
    reloadServices = [ "upload-cloudreve-cname-certificate.service" ];
  };

  systemd.services.upload-cloudreve-cname-certificate = {
    script = ''
      rm -rf ~/{.aliyun,local.xml}
      trap 'rm -rf ~/{.aliyun,local.xml}' EXIT
      ${pkgs.aliyun-cli}/bin/aliyun configure set \
        --profile default \
        --mode EcsRamRole \
        --region ${lib.escapeShellArg aliyunRegion} \
        --ram-role-name ${lib.escapeShellArg aliyunRamRoleName}
      cat <<EOF > local.xml
      <?xml version="1.0" encoding="UTF-8"?>
      <BucketCnameConfiguration>
        <Cname>
          <Domain>${domain}</Domain>
          <CertificateConfiguration>
            <Certificate>
      $(< ${cert.directory}/fullchain.pem)
            </Certificate>
            <PrivateKey>
      $(< ${cert.directory}/key.pem)
            </PrivateKey>
            <Force>true</Force>
          </CertificateConfiguration>
        </Cname>
      </BucketCnameConfiguration>
      EOF
      ${pkgs.aliyun-cli}/bin/aliyun oss bucket-cname \
        --method put --item certificate \
        oss://${lib.escapeShellArg bucketName} local.xml
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "cloudreve-cname";
      Group = "cloudreve-cname";
      StateDirectory = "cloudreve-cname";
      WorkingDirectory = "/var/lib/cloudreve-cname";
    };

  };

  users.users.cloudreve-cname = {
    isSystemUser = true;
    group = "cloudreve-cname";
    home = "/var/lib/cloudreve-cname";
  };
  users.groups.cloudreve-cname = { };

}
