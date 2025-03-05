#!/usr/bin/env python3


import json
import os
import subprocess
import typing
from argparse import ArgumentParser, Namespace
from datetime import datetime
from itertools import chain

import yaml
from pydantic import BaseModel, ConfigDict, Field

try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


class NodeSecrets(BaseModel):
    __pydantic_extra__: dict[str, list[str]] = Field(init=False)  # type: ignore

    model_config = ConfigDict(extra="allow")


def build_source_secret_filepath(source: str) -> str:
    return os.path.join("secrets", "sources", f"{source}.yaml")


def build_node_secret_filepath(node: str) -> str:
    return os.path.join("secrets", "nodes", f"{node}.yaml")


def extract_secret(decrypted: typing.Any, secret_path: list[str]) -> str:
    for key in secret_path:
        decrypted = decrypted[key]
    assert isinstance(decrypted, str), f"Secret {secret_path} is not a string"
    return decrypted


def inject_secret(unencrypted: typing.Any, secret_path: list[str], secret: str) -> None:
    for key in secret_path[:-1]:
        unencrypted = unencrypted.setdefault(key, {})
    unencrypted[secret_path[-1]] = secret


def sync_secrets(args: Namespace) -> None:
    nodes: list[str] = args.node
    # STEP 1: Gather secret by nodes
    node_secrets_raw = subprocess.run(
        [
            "nix",
            "eval",
            ".#nixosConfigurations",
            "--json",
            "--apply",
            f"""\
configs:
let
    nodes = [ {" ".join([f'"{n}"' for n in nodes])} ];
in
builtins.listToAttrs (
    builtins.map (node: {{
        name = node;
        value = (builtins.map (x: x.key) (builtins.attrValues configs.${{node}}.config.sops.secrets));
    }}) nodes)
""",
        ],
        stdout=subprocess.PIPE,
        check=True,
    )
    node_secrets = NodeSecrets.model_validate_json(
        node_secrets_raw.stdout
    ).__pydantic_extra__
    # STEP 2: gather source secret file path
    node_sources: dict[str, set[str]] = {}
    for node, secrets in node_secrets.items():
        node_sources[node] = set(
            [secret.split("/", maxsplit=1)[0] for secret in secrets]
        )

    # STEP 3: check source secret file last modified
    source_last_modified: dict[str, datetime] = {}
    for source in set(chain.from_iterable(node_sources.values())):
        filepath = build_source_secret_filepath(source)
        with open(filepath) as f:
            source_last_modified[source] = datetime.fromisoformat(
                yaml.load(f, Loader=Loader)["sops"]["lastmodified"]
            )
    # STEP 4: check node secret file last modified and skip if not changed
    if not args.force:
        for node in sorted(node_secrets.keys()):
            filepath = build_node_secret_filepath(node)
            if not os.path.exists(filepath):
                continue
            with open(filepath) as f:
                node_last_modified = datetime.fromisoformat(
                    yaml.load(f, Loader=Loader)["sops"]["lastmodified"]
                )
            if all(
                source_last_modified[source] < node_last_modified
                for source in node_sources[node]
            ):
                print(f"Skip {filepath}")
                del node_secrets[node]
                del node_sources[node]
    # STEP 5: decrypt sources
    source_decrypted: dict[str, typing.Any] = {}
    for source in set(chain.from_iterable(node_sources.values())):
        filepath = build_source_secret_filepath(source)
        print(f"Decrypting {filepath}")
        source_decrypted[source] = json.loads(
            subprocess.run(
                ["sops", "decrypt", "--output-type", "json", filepath],
                stdout=subprocess.PIPE,
                check=True,
            ).stdout
        )
    # STEP 6: encrypt node secrets
    for node, secrets in node_secrets.items():
        filepath = build_node_secret_filepath(node)
        print(f"Encrypting {filepath}")
        unencrypted = {}
        for secret in secrets:
            secret_path = secret.split("/")
            secret_value = extract_secret(
                source_decrypted[secret_path[0]], secret_path[1:]
            )
            inject_secret(unencrypted, secret_path, secret_value)
        unencrypted_text = json.dumps(unencrypted)
        subprocess.run(
            [
                "sops",
                "encrypt",
                "--input-type",
                "json",
                "--output",
                filepath,
                "--filename-override",
                filepath,
                "/dev/stdin",
            ],
            input=unencrypted_text.encode(),
            check=True,
        )


def secrets_main() -> None:
    parser = ArgumentParser(description="Secrets manager")
    subparsers = parser.add_subparsers()

    sync_parser = subparsers.add_parser("sync", help="Sync secrets")
    sync_parser.add_argument("--node", help="Node name", nargs="+", type=str)
    sync_parser.add_argument("--force", help="Force sync", action="store_true")
    sync_parser.set_defaults(func=sync_secrets)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    secrets_main()
