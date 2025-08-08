#!/usr/bin/env bash

set -euo pipefail

cert_subject="Kubernetes Intermediate CA"
cert_options=()

ssh_user="root"
ssh_port=22
ssh_options=()

remote_root_ca_cert="/var/lib/step-ca/certs/root_ca.crt"
remote_root_ca_key="/var/lib/step-ca/secrets/root_ca_key"
remote_root_ca_key_password_file="/run/secrets/step-ca/keysPassword"
sign_options=()

k8s_secret_name="k8s-intermediate-ca"
k8s_namespace="cert-manager"
k8s_dry_run=false

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] SSH_HOST

Generate an intermediate CA, sign it remotely, and create a Kubernetes secret.

SSH Options:
  --ssh-user USER                SSH user (default: root)
  --ssh-port PORT                SSH port (default: 22)
  --ssh-option OPTION            Additional SSH options

Certificate Options:
  --cert-subject NAME            Intermediate CA subject (default: Kubernetes Intermediate CA)
  --cert-option OPTION           Intermediate CA certificate create options

Sign Options:
  --ca-cert PATH                 Remote root CA certificate path (default: /var/lib/step-ca/certs/root_ca.crt)
  --ca-key PATH                  Remote root CA key path (default: /var/lib/step-ca/secrets/root_ca_key)
  --ca-key-password-file PATH    Password file for the root CA key (default: /run/secrets/step-ca/keysPassword)
  --sign-option OPTION           Additional step certificate sign options

Kubernetes Options:
  --k8s-secret SECRET            Kubernetes secret name (default: k8s-intermediate-ca)
  --k8s-namespace NAMESPACE      Kubernetes namespace (default: cert-manager)
  --k8s-dry-run                  Dry run Kubernetes secret creation

Other Options:
  -h, --help                     Show this help message

Examples:
  $0 my-ca-server
EOF
}

# Parse command line arguments
positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
  --ssh-user)
    ssh_user="$2"
    shift 2
    ;;
  --ssh-port)
    ssh_port="$2"
    shift 2
    ;;
  --ssh-option)
    ssh_options+=("$2")
    shift 2
    ;;
  --cert-subject)
    cert_subject="$2"
    shift 2
    ;;
  --cert-option)
    cert_options+=("$2")
    shift 2
    ;;
  --ca-cert)
    remote_root_ca_cert="$2"
    shift 2
    ;;
  --ca-key)
    remote_root_ca_key="$2"
    shift 2
    ;;
  --ca-key-password-file)
    remote_root_ca_key_password_file="$2"
    shift 2
    ;;
  --sign-option)
    sign_options+=("$2")
    shift 2
    ;;
  --k8s-secret)
    k8s_secret_name="$2"
    shift 2
    ;;
  --k8s-namespace)
    k8s_namespace="$2"
    shift 2
    ;;
  --k8s-dry-run)
    k8s_dry_run=true
    shift
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  --)
    shift
    positional_args+=("$@")
    break
    ;;
  -*)
    echo "Unknown option: $1"
    show_help
    exit 1
    ;;
  *)
    positional_args+=("$1")
    shift
    ;;
  esac
done

if [[ ${#positional_args[@]} -ne 1 ]]; then
  echo "Error: SSH host is required"
  show_help
  exit 1
fi

ssh_host="${positional_args[0]}"

for exe in kubectl step ssh scp; do
  if ! command -v "$exe" &>/dev/null; then
    echo "Error: $exe command not found. Please install it."
    exit 1
  fi
done

if [[ -z $ssh_host ]]; then
  echo "Error: SSH host is required (--ssh-host)"
  exit 1
fi

if ! kubectl auth can-i create secret "--namespace=$k8s_namespace" >/dev/null; then
  echo "Error: User does not have permission to create TLS secrets in namespace '$k8s_namespace'"
  exit 1
fi
if kubectl get secret "$k8s_secret_name" "--namespace=$k8s_namespace" >/dev/null; then
  echo "Error: Secret '$k8s_secret_name' already exists in namespace '$k8s_namespace'"
  exit 1
fi

cat <<EOF
================================================================================
ssh destination  $ssh_user@$ssh_host
ssh options      -p $ssh_port ${ssh_options[*]}

cert subject     $cert_subject
cert options     ${cert_options[*]}

remote cert      $remote_root_ca_cert
remote key       $remote_root_ca_key
sign options     ${sign_options[*]}

k8s secret       $k8s_namespace/$k8s_secret_name
dry run          $k8s_dry_run
================================================================================
EOF
echo "Are you sure you want to continue? (y/N)"
read -r -n 1 answer
echo
if [[ $answer != "y" && $answer != "Y" ]]; then
  echo "Cancelled."
  exit 1
fi

# Temporary files
temp_dir=$(mktemp -d)
cert_csr_file="$temp_dir/intermediate.csr"
cert_key_file="$temp_dir/intermediate_ca_key"
cert_file="$temp_dir/intermediate.crt"

# Cleanup function
cleanup() {
  echo "Cleaning up..."
  rm -rf "$temp_dir"
}

trap cleanup EXIT

# Step 1: Generate intermediate CA CSR
echo "Generating intermediate CA certificate in $temp_dir..."
step certificate create --csr --no-password --insecure "${cert_options[@]}" \
  "$cert_subject" "$cert_csr_file" "$cert_key_file"

# Step 2: Copy CSR to remote server
scp -P "$ssh_port" "${ssh_options[@]}" "$cert_csr_file" "$ssh_user@$ssh_host:/tmp/intermediate.csr"

# Step 3: Sign the CSR remotely
echo "Signing CSR on remote server..."
step_cmd=(nix run nixpkgs#step-cli -- certificate sign --profile intermediate-ca
  "--password-file=$remote_root_ca_key_password_file" "${sign_options[@]}"
  "/tmp/intermediate.csr" "$remote_root_ca_cert" "$remote_root_ca_key")
# shellcheck disable=SC2029
ssh -p "$ssh_port" "${ssh_options[@]}" "$ssh_user@$ssh_host" \
  "$(printf '%q ' "${step_cmd[@]}")" >"$cert_file"
ssh -p "$ssh_port" "${ssh_options[@]}" "$ssh_user@$ssh_host" \
  "rm -f /tmp/intermediate.csr"

# Step 4: Create Kubernetes secret
echo "Creating Kubernetes secret..."
kubectl_opts=()
if [[ $k8s_dry_run == true ]]; then
  kubectl_opts+=(--dry-run=client -o yaml)
fi
kubectl create secret tls --namespace="$k8s_namespace" "${kubectl_opts[@]}" \
  "$k8s_secret_name" --cert="$cert_file" --key="$cert_key_file"

echo "Successfully created Kubernetes secret '$k8s_secret_name' in namespace '$k8s_namespace'!"
echo

if command -v openssl &>/dev/null; then
  openssl x509 -in "$cert_file" -text -noout
fi
