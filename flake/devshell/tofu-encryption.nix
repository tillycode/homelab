{ ... }:
let
  profile_common = ''
    secrets_file="$PRJ_ROOT/secrets/terraform/tofu-encryption.json"
    profile_base_path="$PRJ_ROOT/terraform"
    profile=""

    validate_profile() {
      if [[ ! "$profile" =~ ^[a-z0-9-]+$ ]]; then
        echo "error: invalid profile name: \"$profile\". Should only contain lowercase letters, numbers, and hyphens" >&2
        exit 1
      fi
    }
  '';

  key_provider_common = ''
    generate_key_provider_name() {
      echo "key_$(pwgen -A -v 5 1)"
    }
    generate_key_provider_passphrase() {
      pwgen -s 32 1
    }
  '';

  tofu-encryption-exec =
    pkgs:
    pkgs.writeShellApplication {
      name = "tofu-encryption-exec";
      runtimeInputs = with pkgs; [
        sops
        jq
      ];
      text = ''
        ${profile_common}

        print_usage() {
          echo "Usage: $(basename "$0") [OPTIONS] [COMMAND [ARGS...]]"
          echo
          echo "Description:"
          echo "  Execute a command with the key provider from a profile"
          echo
          echo "Examples:"
          echo "  $(basename "$0") tofu apply"
          echo "  $(basename "$0") --profile my-profile bash -c 'echo \"\$TF_ENCRYPTION\"'"
          echo
          echo "Options:"
          echo "      --secrets-file <path>       Path to the secrets file (default: $secrets_file)"
          echo "      --profile-base-path <path>  Base path to the profile (default: $profile_base_path)"
          echo "  -p, --profile <profile>         Profile to use from the secrets file. If not provided, it will be inferred from the current directory relative to the profile base path"
          echo "  -h, --help                      Print this help message"
          echo "      --verbose                   Print verbose output"
          echo
        }

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --secrets-file)
              secrets_file="$2"
              shift 2
              ;;
            --profile-base-path)
              profile_base_path="$2"
              shift 2
              ;;
            -p|--profile)
              profile="$2"
              shift 2
              ;;
            -h|--help)
              print_usage
              exit 0
              ;;
            --verbose)
              set -x
              shift
              ;;
            *)
              break
              ;;
          esac
        done

        if [[ -z "$profile" ]]; then
          relative_path="$(realpath -s --relative-to="$profile_base_path" "$(pwd)")"
          profile="$(dirname "$relative_path")"
          if [[ "$profile" == "." ]]; then
            profile="$relative_path"
          fi
          if [[ "$profile" == "." || "$profile" == ".." ]]; then
            echo "error: profile not found. Please either provide a profile with --profile or move to a directory within the profile base path ($profile_base_path)" >&2
            exit 1
          fi
        fi
        validate_profile

        if ! content="$(sops -d --extract "[\"$profile\"]" "$secrets_file")"; then
          exit 1
        fi
        key_provider_name="$(jq -r '.key_provider_name' <<< "$content")"
        key_provider_passphrase="$(jq -r '.key_provider_passphrase' <<< "$content")"
        if [[ -z "$key_provider_name" || -z "$key_provider_passphrase" ]]; then
          echo "error: key provider name or passphrase not found in secrets file" >&2
          exit 1
        fi

        { read -r -d "" TF_ENCRYPTION || true; } <<EOF
        key_provider "pbkdf2" "$key_provider_name" {
          passphrase = "$key_provider_passphrase"
        }
        method "aes_gcm" "new_method" {
          keys = key_provider.pbkdf2.$key_provider_name
        }
        state {
          method = method.aes_gcm.new_method
        }
        plan {
          method = method.aes_gcm.new_method
        }
        EOF

        export TF_ENCRYPTION
        exec "$@"
      '';
    };

  tofu-encryption-add-internal =
    pkgs:
    pkgs.writeShellApplication {
      name = "tofu-encryption-add-internal";
      runtimeInputs = with pkgs; [
        jq
        pwgen
      ];
      text = ''
        ${key_provider_common}

        if [[ "''${verbose:?}" == "y" ]]; then
          set -x
        fi
        key_provider_name="$(generate_key_provider_name)"
        key_provider_passphrase="$(generate_key_provider_passphrase)"

        if ! content="$(jq '
            if has($profile) then
              error("error: profiles already exist")
            else
              .[$profile] = {
                created_at: (now | todate),
                key_provider_name: $name,
                key_provider_passphrase: $passphrase
              }
            end' \
           --arg profile "''${profile:?}" \
           --arg name "''${key_provider_name}" \
           --arg passphrase "''${key_provider_passphrase}" \
           "$1")"; then
          exit 1
        fi
        echo "$content" > "$1"
      '';
    };
  tofu-encryption-remove-internal =
    pkgs:
    pkgs.writeShellApplication {
      name = "tofu-encryption-remove-internal";
      runtimeInputs = with pkgs; [ jq ];
      text = ''
        if [[ "''${verbose:?}" == "y" ]]; then
          set -x
        fi
        if ! content="$(jq '
              if has($profile) then
                del(.[$profile])
              else
                error("error: profile does not exist")
              end' \
            --arg profile "''${profile:?}" \
            "$1")"; then
          exit 1
        fi
        echo "$content" > "$1"
      '';
    };

  tofu-encryption-edit =
    pkgs:
    pkgs.writeShellApplication {
      name = "tofu-encryption-edit";
      runtimeInputs =
        [
          (tofu-encryption-add-internal pkgs)
          (tofu-encryption-remove-internal pkgs)
        ]
        ++ (with pkgs; [
          sops
          jq
        ]);
      text = ''
        ${profile_common}
        force="n"
        verbose="n"

        print_usage() {
          echo "Usage: $(basename "$0") [OPTIONS] {add,remove,list} [PROFILE]"
          echo
          echo "Description:"
          echo "  Add, remove, or list profiles in the secrets file"
          echo
          echo "Examples:"
          echo "  $(basename "$0") add my-profile"
          echo "  $(basename "$0") remove my-profile"
          echo "  $(basename "$0") list"
          echo
          echo "Options:"
          echo "      --secrets-file <path>       Path to the secrets file (default: $secrets_file)"
          echo "      --profile-base-path <path>  Base path to the profile (default: $profile_base_path)"
          echo "      --force                     Force deletion of a profile even if it has state"
          echo "  -h, --help                      Print this help message"
          echo "      --verbose                   Print verbose output"
          echo
        }

        positional=()
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --secrets-file)
              secrets_file="$2"
              shift 2
              ;;
            --profile-base-path)
              profile_base_path="$2"
              shift 2
              ;;
            --force)
              force="y"
              shift
              ;;
            -h|--help)
              print_usage
              exit 0
              ;;
            --verbose)
              set -x
              verbose="y"
              shift
              ;;
            *)
              positional+=("$1")
              shift
              ;;
          esac
        done

        action="''${positional[0]-}"
        case "$action" in
          add)
            EDITOR="tofu-encryption-add-internal"
            ;;
          remove)
            EDITOR="tofu-encryption-remove-internal"
            ;;
          list)
            if [[ "''${#positional[@]}" -ne 1 ]]; then
              echo "error: invalid number of arguments for list command" >&2
              exit 1
            fi
            sops -d "$secrets_file" | jq -r 'to_entries[] | "\(.key)\t\(.value.created_at)\t\(.value.key_provider_name)"'
            exit 0
            ;;
          *)
            echo "error: invalid command: \"''$action\", must be one of: add, remove, list" >&2
            exit 1
            ;;
        esac

        if [[ "''${#positional[@]}" -ne 2 ]]; then
          echo "error: invalid number of arguments for $action command" >&2
          exit 1
        fi
        profile="''${positional[1]-}"
        validate_profile

        profile_dir="$profile_base_path/$profile"
        if [[ "$action" == "remove" && "$force" == "n" && -d "$profile_dir" ]]; then
          echo "error: profile directory exists: $profile_dir" >&2
          exit 1
        fi

        export profile verbose
        EDITOR="$EDITOR" sops "$secrets_file"
      '';
    };

  tofu-encryption-rotate-internal =
    pkgs:
    pkgs.writeShellApplication {
      name = "tofu-encryption-rotate-internal";
      runtimeInputs = with pkgs; [
        jq
        pwgen
      ];
      text = ''
        ${key_provider_common}

        if [[ "''${verbose:?}" == "y" ]]; then
          set -x
        fi
        profile="''${profile:?}"
        profile_dir="''${profile_dir:?}"
        tf="''${tf:?}"

        old_key_provider_name="$(jq -r '.[$profile].key_provider_name' --arg profile "$profile" "$1")"
        old_key_provider_passphrase="$(jq -r '.[$profile].key_provider_passphrase' --arg profile "$profile" "$1")"
        if [[ -z "$old_key_provider_name" || -z "$old_key_provider_passphrase" ]]; then
          echo "error: key provider name or passphrase not found in secrets file" >&2
          exit 1
        fi

        new_key_provider_name="$(generate_key_provider_name)"
        while [[ "$new_key_provider_name" == "$old_key_provider_name" ]]; do
          new_key_provider_name="$(generate_key_provider_name)"
        done
        new_key_provider_passphrase="$(generate_key_provider_passphrase)"

        { read -r -d "" TF_ENCRYPTION || true; } <<EOF
        key_provider "pbkdf2" "$new_key_provider_name" {
          passphrase = "$new_key_provider_passphrase"
        }
        key_provider "pbkdf2" "$old_key_provider_name" {
          passphrase = "$old_key_provider_passphrase"
        }
        method "aes_gcm" "new_method" {
          keys = key_provider.pbkdf2.$new_key_provider_name
        }
        method "aes_gcm" "old_method" {
          keys = key_provider.pbkdf2.$old_key_provider_name
        }
        state {
          method = method.aes_gcm.new_method
          fallback {
            method = method.aes_gcm.old_method
          }
        }
        plan {
          method = method.aes_gcm.new_method
          fallback {
            method = method.aes_gcm.old_method
          }
        }
        EOF

        export TF_ENCRYPTION
        "$tf" -chdir="$profile_dir" apply

        if ! content="$(jq '.[$profile] = {
          created_at: (now | todate),
          key_provider_name: $name,
          key_provider_passphrase: $passphrase
        }' \
          --arg profile "$profile" \
          --arg name "$new_key_provider_name" \
          --arg passphrase "$new_key_provider_passphrase" \
          "$1")"; then
          exit 1
        fi
        echo "$content" > "$1"
      '';
    };

  tofu-encryption-rotate =
    pkgs:
    pkgs.writeShellApplication {
      name = "tofu-encryption-rotate";
      runtimeInputs = [ (tofu-encryption-rotate-internal pkgs) ] ++ (with pkgs; [ sops ]);
      text = ''
        ${profile_common}
        verbose="n"
        tf="$(which tofu)"

        print_usage() {
          echo "Usage: $(basename "$0") [OPTIONS] PROFILE"
          echo
          echo "Description:"
          echo "  Rotate the key provider passphrase for a profile"
          echo
          echo "Examples:"
          echo "  $(basename "$0") my-profile"
          echo
          echo "Options:"
          echo "      --secrets-file <path>            Path to the secrets file (default: $secrets_file)"
          echo "      --profile-base-path <path>       Base path to the profile (default: $profile_base_path)"
          echo "      --tf <path>                      Path to the tofu binary (default: $tf)"
          echo "  -h, --help                           Print this help message"
          echo "      --verbose                        Print verbose output"
          echo
        }

        positional=()
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --secrets-file)
              secrets_file="$2"
              shift 2
              ;;
            --profile-base-path)
              profile_base_path="$2"
              shift 2
              ;;
            --tf)
              tf="$2"
              shift 2
              ;;
            -h|--help)
              print_usage
              exit 0
              ;;
            --verbose)
              set -x
              verbose="y"
              shift
              ;;
            *)
              positional+=("$1")
              shift
              ;;
          esac
        done

        if [[ "''${#positional[@]}" -ne 1 ]]; then
          echo "error: invalid number of arguments" >&2
          exit 1
        fi

        profile="''${positional[0]}"
        validate_profile

        profile_dir="$profile_base_path/$profile"
        if [[ ! -d "$profile_dir" ]]; then
          echo "error: profile directory not found: $profile_dir" >&2
          exit 1
        fi

        export tf profile profile_dir verbose
        EDITOR="tofu-encryption-rotate-internal" sops "$secrets_file"
      '';
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.default = {
        commands = [
          rec {
            category = "terraform";
            name = "tofu-encryption";
            help = "Mange OpenTofu encryption profiles";
            package = pkgs.writeShellApplication {
              name = "tofu-encryption";
              runtimeInputs = [
                (tofu-encryption-exec pkgs)
                (tofu-encryption-edit pkgs)
                (tofu-encryption-rotate pkgs)
              ];
              text = ''

                print_usage() {
                  echo "Usage: $(basename "$0") {exec,edit,rotate} [ARGS...]"
                  echo
                  echo "Description:"
                  echo "  ${help}"
                  echo
                  echo "Examples:"
                  echo "  $(basename "$0") --help"
                  echo "  $(basename "$0") edit --help"
                  echo "  $(basename "$0") rotate --help"
                  echo "  $(basename "$0") exec --help"
                  echo
                  echo "Options:"
                  echo "  -h, --help  Print this help message"
                  echo
                }

                while [[ $# -gt 0 ]]; do
                  case "$1" in
                    -h|--help)
                      print_usage
                      exit 0
                      ;;
                    *)
                      break
                      ;;
                  esac
                done

                if [[ $# -eq 0 ]]; then
                  echo "error: missing command. Please provide one of: exec, edit, rotate" >&2
                  exit 1
                fi

                command="$1"
                shift
                case "$command" in
                  exec)
                    exec tofu-encryption-exec "$@"
                    ;;
                  edit)
                    exec tofu-encryption-edit "$@"
                    ;;
                  rotate)
                    exec tofu-encryption-rotate "$@"
                    ;;
                  *)
                    echo "error: invalid command: \"$command\"" >&2
                    exit 1
                    ;;
                esac
              '';
            };
          }
        ];
      };
    };
}
