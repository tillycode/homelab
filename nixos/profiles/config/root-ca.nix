let
  # curl https://acme.svc.szp.io/roots.pem -o certs/roots.pem
  szp-io = builtins.readFile ../../../certs/roots.pem;
in
{
  security.pki.certificates = [ szp-io ];
}
