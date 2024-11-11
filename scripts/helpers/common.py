import subprocess
from argparse import ArgumentParser, Namespace

from pydantic import BaseModel


class Connection(BaseModel):
    system: str
    ssh_host: str
    ssh_port: int | None = None
    ssh_user: str | None = None
    bastion_host: str | None = None
    bastion_port: int | None = None
    bastion_user: str | None = None

    @staticmethod
    def add_argument_parser(parser: ArgumentParser) -> None:
        parser.add_argument("--node", type=str, help="node name", required=True)

    @staticmethod
    def from_args(args: Namespace) -> "Connection":
        output = subprocess.run(
            [
                "nix",
                "eval",
                "--json",
                ".#lib.data.nodes",
                "--apply",
                f"""
x:
{{
  inherit (x."{args.node}") ssh_host ssh_port ssh_user
    bastion_host bastion_port bastion_user system;
}}""",
            ],
            check=True,
            stdout=subprocess.PIPE,
        )
        return Connection.model_validate_json(output.stdout)
