{
  inputs,
  lib,
  ...
}:
let
  sops-keys = {
    # ziping_sun
    pgp = [
      "8CC5C91F72DB57DA20BD848C6523836CF4992251"
    ];
    kms = [
      # github-actions
      { arn = "arn:aws:kms:ap-southeast-1:137927498482:alias/sops-key"; }
    ];
  };
  node-keys = {
    hgh0 = "age1f8jdv6xagt92t44qhnnflkazfe03rry0w6da2eqdv3dwkwppwatqxkgj9w";
    hgh1 = "age1ydjlaersukg2jms5hrjz7z2ja0htlln40uexcmcg2yxzlny8s39qc88wya";
    hgh2 = "age1q93v8zc62mczmz30wy04n8erlfhhhjc3k7a3vspccjqpvehxadyqgrzrue";
    sha0 = "age1a46mp4kgk3jdvt520ng9ta45zv0ns0xts9xvjza04t3mpmrfjdqs52s6vh";
    sin0 = "age1pf03m77v3wpz4qtzc6nrlkvj4pdxffpwtg789g8zjq753hj2ug8qnsnttt";
    desktop = "age1v6lnkm7prm0dpmcdpvn44v50rpfkzsed5uv3znxt4grsd5y6sv5qjru9qq";
  };
  sops_source_creation_rule = {
    path_regex = "^secrets/sources/.*\\.yaml$";
    key_groups = [ sops-keys ];
  };
  sops_host_creation_rules = lib.pipe node-keys [
    lib.attrsToList
    (lib.map (
      { name, value }:
      {
        path_regex = "^secrets/nodes/${name}\\.yaml$";
        key_groups = [ { age = [ value ]; } ];
      }
    ))
  ];
in
{
  # docs: https://numtide.github.io/devshell/modules_schema.html
  imports = [
    inputs.devshell.flakeModule
    inputs.git-hooks-nix.flakeModule
    ./deploy.nix
    ./treefmt.nix
    ./pre-commit.nix

    ## commands
    ./tofu-encryption.nix
  ];
  perSystem =
    { config, pkgs, ... }:
    {
      nixago.configs = [
        {
          data = {
            creation_rules = [
              sops_source_creation_rule
            ] ++ sops_host_creation_rules;
          };
          format = "yaml";
          output = "lib/.sops.yaml";
        }
      ];

      devshells.default = {
        devshell.packages = with pkgs; [
          opentofu
          cachix
          aws-vault
          awscli2
          terragrunt
          terraform-ls
          gh
          aliyun-cli
          jq
          sops
          ssh-to-age
          vault
          nvfetcher
          go-task
          python3
          uv
        ];
        devshell.startup = {
          nixago.text = config.nixago.shellHook;
          pre-commit-hook.text = config.pre-commit.installationScript;
        };
      };

      devshells.deploy = {
        devshell.motd = "Welcome to CI/CD shell";
        devshell.packages = with pkgs; [
          opentofu
          terragrunt
          jq
          sops
          ssh-to-age
          deploy-rs.deploy-rs
        ];

        commands = [
          {
            package = pkgs.writeShellApplication {
              name = "setup";
              runtimeInputs = with pkgs; [
                openssh
                attic-client
              ];
              text = ''
                echo "Setting up PATH"
                echo "$DEVSHELL_DIR/bin" >>"$GITHUB_PATH"

                echo "Setting up ssh-agent"
                declare SSH_AUTH_SOCK SSH_AGENT_PID
                eval "$(ssh-agent -s)"
                echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >>"$GITHUB_ENV"
                echo "SSH_AGENT_PID=$SSH_AGENT_PID" >>"$GITHUB_ENV"

                echo "Adding private key to ssh-agent"
                ssh-add - <<<"$SSH_PRIVATE_KEY"

                echo "Setting up binary cache"
                attic login --set-default default "$ATTIC_ENDPOINT" "$ATTIC_TOKEN"
                ATTIC_LOG=$(mktemp)
                attic use default
                nohup attic watch-store default >"$ATTIC_LOG" 2>&1 &
                ATTIC_PID=$!
                echo "ATTIC_LOG=$ATTIC_LOG" >>"$GITHUB_ENV"
                echo "ATTIC_PID=$ATTIC_PID" >>"$GITHUB_ENV"
              '';
              meta = {
                description = "setup GitHub Actions environment";
              };
            };
          }
          {
            package = pkgs.writeShellApplication {
              name = "teardown";
              runtimeInputs = with pkgs; [ openssh ];
              text = ''
                echo "Killing ssh-agent"
                ssh-agent -k

                echo "Killing attic"
                kill -INT "$ATTIC_PID"
                tail -n +1 --pid "$ATTIC_PID" -f "$ATTIC_LOG"
                rm "$ATTIC_LOG"
              '';
              meta = {
                description = "teardown GitHub Actions environment";
              };
            };
          }
        ];
      };

      checks."devshell-default" = config.devShells.default;
      checks."devshell-deploy" = config.devShells.deploy;
    };
}
