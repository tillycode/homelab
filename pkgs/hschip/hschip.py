#!/usr/bin/env python3

import argparse
import sqlite3
import sys


def process_ip(
    c: sqlite3.Cursor,
    node_id: int,
    node_name: str,
    old_ip: str,
    new_ip: str,
    ip_type: str,
    disable_swap_on_conflict: bool,
) -> None:
    c.execute(
        f"SELECT id, given_name FROM nodes WHERE {ip_type} = ? AND id != ?",
        (new_ip, node_id),
    )
    conflict_node = c.fetchone()
    if conflict_node is not None:
        conflict_node_id, conflict_node_given_name = conflict_node
        if disable_swap_on_conflict:
            print(
                f"{ip_type} address {new_ip} is already in use by node {conflict_node_given_name}",
                file=sys.stderr,
            )
            sys.exit(1)
        c.execute(
            f"UPDATE nodes SET {ip_type} = ? WHERE id = ?",
            (old_ip, conflict_node_id),
        )
        print(
            f"{ip_type} address of node {conflict_node_given_name} changed from {new_ip} to {old_ip}"
        )
    c.execute(
        f"UPDATE nodes SET {ip_type} = ? WHERE id = ?",
        (new_ip, node_id),
    )
    print(f"{ip_type} address of node {node_name} changed from {old_ip} to {new_ip}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="A script to change node IP address in the headscale database"
    )
    parser.add_argument(
        "given_name",
        type=str,
        help="The given name of the node",
    )
    parser.add_argument(
        "ip",
        type=str,
        help="The new IP address of the node",
        nargs="+",
    )
    parser.add_argument(
        "--db",
        type=str,
        help="The path to the headscale database (default: /var/lib/headscale/db.sqlite)",
        default="/var/lib/headscale/db.sqlite",
    )
    parser.add_argument(
        "--disable-swap-on-conflict",
        action="store_true",
        help="Disable swapping IP addresses when there is a conflict",
    )
    parser.add_argument(
        "--fail-on-not-found",
        action="store_true",
        help="Fail if the node is not found",
    )
    args = parser.parse_args()

    # parse the IP addresses
    new_ipv4, new_ipv6 = None, None
    for ip in args.ip:
        if ":" in ip:
            if new_ipv6 is not None:
                print("Only one IPv6 address is allowed", file=sys.stderr)
                sys.exit(1)
            new_ipv6 = ip
        else:
            if new_ipv4 is not None:
                print("Only one IPv4 address is allowed", file=sys.stderr)
                sys.exit(1)
            new_ipv4 = ip

    conn = sqlite3.connect(args.db, autocommit=False)
    c = conn.cursor()

    # check the existences of the node and get its IPs
    c.execute(
        "SELECT id, ipv4, ipv6 FROM nodes WHERE given_name = ?",
        (args.given_name,),
    )
    node = c.fetchone()
    if node is None:
        print(f"Node {args.given_name} not found", file=sys.stderr)
        sys.exit(1 if args.fail_on_not_found else 0)
    node_id, old_ipv4, old_ipv6 = node

    # process IPv4
    if new_ipv4 is not None and old_ipv4 != new_ipv4:
        process_ip(
            c,
            node_id,
            args.given_name,
            old_ipv4,
            new_ipv4,
            "ipv4",
            args.disable_swap_on_conflict,
        )

    # process IPv6
    if new_ipv6 is not None and old_ipv6 != new_ipv6:
        process_ip(
            c,
            node_id,
            args.given_name,
            old_ipv6,
            new_ipv6,
            "ipv6",
            args.disable_swap_on_conflict,
        )

    conn.commit()


if __name__ == "__main__":
    main()
