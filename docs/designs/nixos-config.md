# NixOS Configuration

## Considerations

### Code Organization

In my [previous NixOS project](https://github.com/sunziping2016/flakes),
I faced difficulties in maintaining the growing configurations.
It became challenging to create new modules and understand the final configurations.
Therefore, I decided to start over and rethink the design.

I was greatly inspired by [Yinfeng Lin's NixOS configurations](https://github.com/linyinfeng/dotfiles),
which separate NixOS configurations into three parts within the `nixos` directory:

1. **Modules**: These modules, by default, do not alter the NixOS configuration, making them safe to import.
2. **Profiles**: A profile modifies the NixOS configuration once it is imported. Multiple profiles can be grouped into a **suite** for more concise imports.
3. **Hosts**: A host is a selective collection of profiles and suites.

### Data Management

Using the previous method made it tedious to manage frequently updated profiles.
For example, adding, removing, or inspecting SSH authorized keys on each machine required multiple steps.
I had to check all the profiles related to SSH authorized keys and the host-profile relationship
to fully understand the current configuration.

Another issue arises from program-generated data.
One of the principles of this project is to ensure a **single source of truth**.
For instance, the source of truth for the root CA comes from the Vault server.
To make the root CA available to NixOS configurations, I had to use a tool,
such as Terraform, to fetch the root CA from the Vault server and store it as a NixOS profile.
This process becomes increasingly messy as more programs write their output directly into NixOS profiles.

To address these challenges, I propose introducing **dynamic profiles**.
We can treat a profile as an instance of a module.
If there aren't too many _instances_ of a module,
it is sufficient to make each of these _instances_ a **static profile**.
Otherwise, we need to formalize these instances as dynamic profiles, parameterized by some data.
