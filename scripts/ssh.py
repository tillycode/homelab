#!/usr/bin/env python3

import argparse
import os

from helpers.common import Connection


def ssh_main() -> None:
    parser = argparse.ArgumentParser()
    Connection.add_argument_parser(parser)
    args, extra_args = parser.parse_known_args()

    connection = Connection.from_args(args)
    ssh_args: list[str] = [
        "-p",
        f"{connection.ssh_port or 22}",
    ]
    if connection.bastion_host is not None:
        ssh_args += [
            "-o",
            f"ProxyJump={connection.bastion_user or 'root'}@{connection.bastion_host}:{connection.bastion_port or 22}",
        ]
    ssh_args += [
        f"{connection.ssh_user or 'root'}@{connection.ssh_host}",
    ]
    os.execlp("ssh", "ssh", *ssh_args, *extra_args)


if __name__ == "__main__":
    ssh_main()
