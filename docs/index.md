# Welcome to MkDocs

For full documentation visit [mkdocs.org](https://www.mkdocs.org).

## Commands

- `mkdocs new [dir-name]` - Create a new project.
- `mkdocs serve` - Start the live-reloading docs server.
- `mkdocs build` - Build the documentation site.
- `mkdocs -h` - Print help message and exit.

## Project layout

```text
flake/              # flakeModule configurations
flake-modules/      # flakeModule options
lib/                # data & function
nixos/              # nixosConfigurations
  hosts/            # definition of hosts
  modules/          # nixosModule options
  profiles/         # nixosModule configuration
templates/          # templates
terraform/          # *.tf
```

## Data flow

```mermaid
Terraform outputs + lib/data/config.toml -> lib/data/data.json
data.json + *.nix -> nixosConfigurations
```
