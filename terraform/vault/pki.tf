resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  description               = "PKI mount"
  default_lease_ttl_seconds = 86400     # 1 day
  max_lease_ttl_seconds     = 315360000 # 1 year
}

resource "vault_pki_secret_backend_root_cert" "root_2024" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "k8s.szp.io"
  ttl         = 315360000
  issuer_name = "root-2024"
}

resource "vault_pki_secret_backend_issuer" "root_2024" {
  backend                        = vault_mount.pki.path
  issuer_ref                     = vault_pki_secret_backend_root_cert.root_2024.issuer_id
  issuer_name                    = vault_pki_secret_backend_root_cert.root_2024.issuer_name
  revocation_signature_algorithm = "SHA256WithRSA"
}

resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["http://vault.vault:8200/v1/pki/ca"]
  crl_distribution_points = ["http://vault.vault:8200/v1/pki/crl"]
}

resource "vault_mount" "pki_int" {
  path        = "pki_int"
  type        = "pki"
  description = "Intermediate PKI mount"

  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 157680000
}

resource "vault_pki_secret_backend_intermediate_cert_request" "csr_request" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "k8s.szp.io Intermediate Authority"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend     = vault_mount.pki.path
  common_name = "k8s.szp.io Intermediate Authority"
  csr         = vault_pki_secret_backend_intermediate_cert_request.csr_request.csr
  format      = "pem_bundle"
  ttl         = 15480000
  issuer_ref  = vault_pki_secret_backend_root_cert.root_2024.issuer_id
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

resource "vault_pki_secret_backend_issuer" "intermediate" {
  backend                        = vault_mount.pki_int.path
  issuer_ref                     = vault_pki_secret_backend_intermediate_set_signed.intermediate.imported_issuers[0]
  issuer_name                    = "intermediate"
  revocation_signature_algorithm = "SHA256WithRSA"
}

resource "vault_pki_secret_backend_role" "intermediate_role" {
  backend          = vault_mount.pki_int.path
  issuer_ref       = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  name             = "k8s-szp-io"
  ttl              = 86400
  max_ttl          = 2592000
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allowed_domains  = ["k8s.szp.io"]
  allow_subdomains = true
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default:443"
  disable_iss_validation = true
}

resource "vault_policy" "pki_int" {
  name = "pki_int"

  policy = <<EOF
path "pki_int/*"                  { capabilities = ["read", "list"] }
path "pki_int/sign/k8s-szp-io"    { capabilities = ["create", "update"] }
path "pki_int/issue/k8s-szp-io"   { capabilities = ["create"] }
EOF
}

resource "vault_kubernetes_auth_backend_role" "issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault-issuer"
  bound_service_account_names      = ["vault-issuer"]
  bound_service_account_namespaces = ["cert-manager"]
  audience                         = "vault://vault-issuer"
  token_policies                   = ["pki_int"]
  token_max_ttl                    = 20 * 60
}
