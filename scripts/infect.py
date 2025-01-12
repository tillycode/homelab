#!/usr/bin/env python3


import argparse
import os
import subprocess

from helpers.common import Connection


def infect_main() -> None:
    parser = argparse.ArgumentParser()
    Connection.add_argument_parser(parser)
    parser.add_argument("--nixos-images-version", default="nixos-24.11")
    parser.add_argument("--nixos-anywhere-version", default="1.6.0")
    parser.add_argument("--use-cached-image", action="store_true")
    args = parser.parse_args()

    connection = Connection.from_args(args)

    nixos_anywhere_args: list[str] = [
        "--print-build-logs",
        "--no-substitute-on-destination",
        "--flake",
        f".#{args.node}",
        "--ssh-port",
        f"{connection.ssh_port or 22}",
    ]
    if connection.bastion_host is not None:
        nixos_anywhere_args += [
            "--ssh-option",
            f"ProxyJump={connection.bastion_user or 'root'}@{connection.bastion_host}:{connection.bastion_port or 22}",
        ]
    image_path = os.path.join(
        ".data",
        "nixos-images",
        f"nixos-kexec-installer-noninteractive-{connection.system}.tar.gz",
    )
    if not args.use_cached_image:
        os.makedirs(os.path.dirname(image_path), exist_ok=True)
        subprocess.run(
            [
                "curl",
                "-fSL",
                "-o",
                image_path,
                f"https://github.com/nix-community/nixos-images/releases/download/{args.nixos_images_version}/nixos-kexec-installer-noninteractive-{connection.system}.tar.gz",
            ],
            check=True,
        )
    elif not os.path.exists(image_path):
        raise FileNotFoundError(image_path)
    nixos_anywhere_args += [
        "--kexec",
        image_path,
        f"{connection.ssh_user or 'root'}@{connection.ssh_host}",
    ]
    os.execlp(
        "nix",
        "nix",
        "run",
        f"github:nix-community/nixos-anywhere/{args.nixos_anywhere_version}#nixos-anywhere",
        "--",
        *nixos_anywhere_args,
    )


if __name__ == "__main__":
    infect_main()
