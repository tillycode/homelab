let
  k8s-szp-io = builtins.readFile ../../../generated/k8s-szp-io.crt;
in
{
  security.pki.certificates = [ k8s-szp-io ];
}
