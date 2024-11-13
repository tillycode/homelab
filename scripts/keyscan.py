#!/usr/bin/env python3
import argparse
import subprocess

from helpers.common import Connection
from pydantic import AliasGenerator, BaseModel, ConfigDict


class KebabCaseBaseModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=AliasGenerator(
            serialization_alias=lambda x: x.replace("_", "-")
        )
    )


class KeyScanNode(KebabCaseBaseModel):
    ssh_keys: list[str]
    age_key: str


class KeyScanOutput(KebabCaseBaseModel):
    node_keys: dict[str, KeyScanNode]


def keyscan_main() -> None:
    parser = argparse.ArgumentParser()
    Connection.add_argument_parser(parser)
    parser.add_argument("--output", type=str)
    args = parser.parse_args()

    connection = Connection.from_args(args)
    cmd = [
        "ssh-keyscan",
        "-p",
        str(connection.ssh_port or 22),
        connection.ssh_host,
    ]
    if connection.bastion_host is not None:
        cmd = [
            "ssh",
            "-p",
            str(connection.bastion_port or 22),
            f"{connection.bastion_user or "root"}@{connection.bastion_host}",
        ] + cmd
    keyscan = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    ssh_keys = keyscan.stdout.decode("utf-8").splitlines()
    ssh_keys = [line for line in ssh_keys if not line.startswith("#")]
    # omit hosts and make sure the output is deterministic
    ssh_keys = sorted([line.split(" ", 1)[1] for line in ssh_keys])
    assert ssh_keys, "No SSH keys found"

    ssh_to_age = subprocess.run(
        ["ssh-to-age"],
        input=keyscan.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    age_key = ssh_to_age.stdout.decode("utf-8").strip()
    assert age_key, "No age key found"
    assert "\n" not in age_key, "Multiple age keys found"
    output = KeyScanOutput(
        node_keys={
            args.node: KeyScanNode(
                ssh_keys=ssh_keys,
                age_key=age_key,
            ),
        }
    ).model_dump_json(by_alias=True)
    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
    else:
        print(output)


if __name__ == "__main__":
    keyscan_main()
