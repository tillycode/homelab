{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.default = {
        commands = [
          {
            category = "deployment";
            name = "nixos-image";
            help = "Download NixOS kexec installer image for a given architecture";
            package = pkgs.writeShellApplication {
              name = "nixos-image";
              runtimeInputs = with pkgs; [ util-linux ];
              text = ''
                BRANCH=nixos-24.05
                allowed_ARCH=(x86_64 aarch64)

                print_usage() {
                  echo "Usage: nixos-image [--branch BRANCH] ARCH"
                  echo
                  echo "  --branch BRANCH  NixOS release branch to download from (default: $BRANCH)"
                  echo
                  echo "Supported architectures: ''${allowed_ARCH[*]}"
                }

                positionals=()

                while [[ $# -gt 0 ]]; do
                  case $1 in
                    --branch)
                      BRANCH=$2
                      shift 2
                      ;;
                    -h|--help)
                      print_usage
                      exit 0
                      ;;
                    *)
                      positionals+=("$1")
                      shift
                      ;;
                  esac
                done
                if [[ ''${#positionals[@]} -ne 1 ]]; then
                  print_usage >&2
                  exit 1
                fi

                ARCH=''${positionals[0]}
                arch_found=
                for i in "''${allowed_ARCH[@]}"; do
                  if [[ "$i" == "$ARCH" ]]; then
                    arch_found=1
                    break
                  fi
                done
                if [[ -z $arch_found ]]; then
                  echo "Invalid architecture: $ARCH. Allowed values: ''${allowed_ARCH[*]}"
                  exit 1
                fi

                mkdir -p "$PRJ_DATA_DIR/nixos-images"
                cd "$PRJ_DATA_DIR/nixos-images"

                lock_file=".$BRANCH-$ARCH.lock"
                etag_file=".$BRANCH-$ARCH.etag"
                etag_file_tmp="$etag_file.tmp"
                output_file="nixos-kexec-installer-noninteractive-$ARCH-linux.tar.gz"
                output_file_tmp="$output_file.tmp"

                trap 'rm -f "$etag_file_tmp" "$output_file_tmp"' EXIT
                (
                  flock -x 9

                  curl -fL --compressed --etag-compare "$etag_file" --etag-save "$etag_file_tmp" --output "$output_file_tmp" \
                    "https://github.com/nix-community/nixos-images/releases/download/$BRANCH/nixos-kexec-installer-noninteractive-$ARCH-linux.tar.gz"
                  if [[ -f "$output_file_tmp" ]]; then
                    mv "$output_file_tmp" "$output_file"
                    mv "$etag_file_tmp" "$etag_file"
                  fi
                  echo "$PRJ_DATA_DIR/nixos-images/$output_file"
                ) 9>"$lock_file"
              '';
            };
          }
          {
            category = "deployment";
            name = "deploy";
            package = pkgs.deploy-rs.deploy-rs;
          }
        ];
      };
    };
}
