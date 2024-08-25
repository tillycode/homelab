{
  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    ClientAliveInterval 60
    ClientAliveCountMax 2
  '';
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/" # sun@desktop
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM" # yubikey
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNlekmLqIMn8zTkjU2sU4StemRV+wQvoMMvqmIIJxT6" # github-action
  ];
}
