#!/usr/bin/env python3
"""Install shared Ubuntu packages and prepare users for rootless Podman."""

from __future__ import annotations

import argparse
import os
import pwd
import re
import subprocess
import sys
from pathlib import Path

SUBID_START = 100_000
SUBID_COUNT = 65_536
USERNAME = re.compile(r"[a-z_][a-z0-9_-]{0,31}")

PACKAGES = (
    "acl",
    "build-essential",
    "ca-certificates",
    "curl",
    "dbus-user-session",
    "direnv",
    "file",
    "fuse-overlayfs",
    "gh",
    "git",
    "git-lfs",
    "jq",
    "less",
    "lf",
    "libsecret-tools",
    "openssh-client",
    "podman",
    "python3",
    "python3-venv",
    "python-is-python3",
    "rsync",
    "shellcheck",
    "slirp4netns",
    "uidmap",
    "unzip",
    "xz-utils",
    "zip",
    "zstd",
)


def log(message: str) -> None:
    print(f"[system-setup] {message}", flush=True)


def run(*args: str, env: dict[str, str] | None = None) -> None:
    log(f"running: {' '.join(args)}")
    subprocess.run(args, check=True, env=env)


def os_release() -> dict[str, str]:
    values: dict[str, str] = {}
    for line in Path("/etc/os-release").read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value.strip('"')
    return values


def allocated_ranges(path: Path) -> list[tuple[int, int]]:
    ranges = []
    for line in path.read_text().splitlines():
        try:
            _, start, count = line.split(":")
            ranges.append((int(start), int(count)))
        except ValueError:
            continue
    return ranges


def next_subid(path: Path) -> int:
    next_id = max(
        (start + count for start, count in allocated_ranges(path)),
        default=SUBID_START,
    )
    next_id = max(next_id, SUBID_START)
    remainder = (next_id - SUBID_START) % SUBID_COUNT
    return next_id if remainder == 0 else next_id + SUBID_COUNT - remainder


def has_subid(path: Path, username: str) -> bool:
    return any(
        line.partition(":")[0] == username for line in path.read_text().splitlines()
    )


def ensure_subid(username: str, path: Path, flag: str) -> None:
    if has_subid(path, username):
        return
    start = next_subid(path)
    end = start + SUBID_COUNT - 1
    run("usermod", flag, f"{start}-{end}", username)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("users", nargs="*", help="existing Unix users to configure")
    return parser.parse_args()


def regular_users() -> list[str]:
    """Return normal login users, excluding nobody and system accounts."""
    return sorted(
        entry.pw_name
        for entry in pwd.getpwall()
        if 1_000 <= entry.pw_uid < 65_534
        and entry.pw_shell not in {"/usr/sbin/nologin", "/bin/false"}
    )


def main() -> None:
    args = parse_args()
    if os.geteuid() != 0:
        sys.exit("setup_system.py must run as root")

    release = os_release()
    if release.get("ID") != "ubuntu" or release.get("VERSION_ID") != "24.04":
        sys.exit(
            "Ubuntu 24.04 is required "
            f"(found {release.get('ID', 'unknown')} {release.get('VERSION_ID', 'unknown')})"
        )

    users = args.users or regular_users()
    if not args.users:
        log(f"auto-detected login users: {', '.join(users) if users else '(none)'}")

    for username in users:
        if not USERNAME.fullmatch(username):
            sys.exit(f"invalid Unix username: {username!r}")
        try:
            pwd.getpwnam(username)
        except KeyError:
            raise SystemExit(f"user does not exist: {username}") from None

    apt_env = {**os.environ, "DEBIAN_FRONTEND": "noninteractive"}
    run("apt-get", "update", env=apt_env)
    run(
        "apt-get",
        "install",
        "-y",
        "--no-install-recommends",
        *PACKAGES,
        env=apt_env,
    )
    run("git", "lfs", "install", "--system")

    for username in users:
        log(f"configuring rootless Podman prerequisites for {username}")
        ensure_subid(username, Path("/etc/subuid"), "--add-subuids")
        ensure_subid(username, Path("/etc/subgid"), "--add-subgids")
        run("loginctl", "enable-linger", username)

    if not users:
        log("no login users found; user Podman setup skipped")
    log("system setup complete")


if __name__ == "__main__":
    main()
