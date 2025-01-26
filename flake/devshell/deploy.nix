{ pkgs, config, ... }:
{
  devshells.deploy = {
    devshell.motd = "Welcome to CI/CD shell";
    devshell.packages = with pkgs; [
      terragrunt
      opentofu
      deploy-rs.deploy-rs
      sops
      jq
      ssh-to-age
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

  checks."devshell/deploy" = config.devShells.deploy;
}
