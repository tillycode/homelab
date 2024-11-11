{ inputs, ... }:
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
      nixago.configs = [ ];

      devshells.deploy = {
        devshell.motd = "Welcome to CI/CD shell";
        devshell.packages = with pkgs; [
          openssh
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
              text = ''
                echo "Setting up PATH"
                echo "$DEVSHELL_DIR/bin" >>"''${GITHUB_PATH:-/dev/stderr}"

                echo "Setting up ssh-agent"
                declare SSH_AUTH_SOCK SSH_AGENT_PID
                eval "$(ssh-agent -s)"
                echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >>"''${GITHUB_ENV:-/dev/stderr}"
                echo "SSH_AGENT_PID=$SSH_AGENT_PID" >>"''${GITHUB_ENV:-/dev/stderr}"

                echo "Adding private key to ssh-agent"
                if [[ -n "''${SSH_PRIVATE_KEY:-}" ]]; then
                  ssh-add - <<<"$SSH_PRIVATE_KEY"
                else
                  echo "SSH_PRIVATE_KEY is not set"
                fi

                echo "Setting up SSH known_hosts"
                mkdir -p ~/.ssh
                chmod 700 ~/.ssh
                cat generated/known_hosts >>~/.ssh/known_hosts
              '';
              meta = {
                description = "setup GitHub Actions environment";
              };
            };
          }
        ];
      };

      checks."devshell-default" = config.devShells.default;
      checks."devshell-deploy" = config.devShells.deploy;
    };
}
