# Enable sshd.service
{
  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    ClientAliveInterval 60
    ClientAliveCountMax 2
  '';
}
