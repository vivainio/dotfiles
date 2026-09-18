#!/usr/bin/env python3
"""Install per-user AI development tools without storing credentials."""

from __future__ import annotations

import hashlib
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

NODE_MAJOR = 22
HOME = Path.home()
LOCAL_BIN = HOME / ".local" / "bin"
NODE_ROOT = HOME / ".local" / "share" / f"node-v{NODE_MAJOR}"
SCRIPT_DIR = Path(__file__).resolve().parent
TOOLS_RECIPE = SCRIPT_DIR / "wsl-tools.toml"
ZIPGET_URL = (
    "https://github.com/vivainio/zipget-rs/releases/latest/download/"
    "zipget-linux-x64-musl"
)


def log(message: str) -> None:
    print(f"[user-setup] {message}", flush=True)


def run(
    *args: str,
    env: dict[str, str] | None = None,
    cwd: Path | None = None,
) -> None:
    log(f"running: {' '.join(args)}")
    subprocess.run(args, check=True, env=env, cwd=cwd)


def download(url: str, destination: Path) -> None:
    log(f"downloading {url}")
    request = urllib.request.Request(url, headers={"User-Agent": "linux-vibe-setup"})
    with urllib.request.urlopen(request, timeout=120) as response:  # noqa: S310
        destination.write_bytes(response.read())


def node_architecture() -> str:
    machine = platform.machine().lower()
    try:
        return {"x86_64": "x64", "aarch64": "arm64", "arm64": "arm64"}[machine]
    except KeyError:
        sys.exit(f"unsupported CPU architecture: {machine}")


def find_node_archive(checksums: str, architecture: str) -> tuple[str, str]:
    suffix = f"-linux-{architecture}.tar.xz"
    for line in checksums.splitlines():
        digest, _, filename = line.partition("  ")
        if filename.endswith(suffix):
            return filename, digest
    sys.exit(f"no Node.js {NODE_MAJOR} archive found for {architecture}")


def install_node(temp: Path) -> None:
    base_url = f"https://nodejs.org/dist/latest-v{NODE_MAJOR}.x"
    checksums_path = temp / "SHASUMS256.txt"
    download(f"{base_url}/SHASUMS256.txt", checksums_path)
    filename, expected_digest = find_node_archive(
        checksums_path.read_text(), node_architecture()
    )

    archive = temp / filename
    download(f"{base_url}/{filename}", archive)
    actual_digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if actual_digest != expected_digest:
        sys.exit("Node.js checksum verification failed")

    shutil.rmtree(NODE_ROOT, ignore_errors=True)
    NODE_ROOT.mkdir(parents=True)
    with tarfile.open(archive, "r:xz") as bundle:
        members = bundle.getmembers()
        top_directory = Path(members[0].name).parts[0]
        for member in members:
            member.name = str(Path(member.name).relative_to(top_directory))
            if member.name != ".":
                bundle.extract(member, NODE_ROOT, filter="data")

    for executable in ("node", "npm", "npx", "corepack"):
        link = LOCAL_BIN / executable
        link.unlink(missing_ok=True)
        link.symlink_to(NODE_ROOT / "bin" / executable)


def install_zipget() -> Path:
    zipget = LOCAL_BIN / "zipget"
    if not zipget.exists():
        download(ZIPGET_URL, zipget)
        zipget.chmod(0o755)
    return zipget


def install_recipe_tools(zipget: Path) -> None:
    if not TOOLS_RECIPE.is_file():
        sys.exit(f"missing zipget recipe: {TOOLS_RECIPE}")
    run(str(zipget), "recipe", str(TOOLS_RECIPE), cwd=SCRIPT_DIR)

    aws_installer = SCRIPT_DIR / "aws-cli-installer" / "aws" / "install"
    if not aws_installer.is_file():
        sys.exit(f"zipget did not produce the AWS CLI installer at {aws_installer}")
    args = [
        str(aws_installer),
        "--install-dir",
        str(HOME / ".local" / "aws-cli"),
        "--bin-dir",
        str(LOCAL_BIN),
    ]
    if (HOME / ".local" / "aws-cli").exists():
        args.append("--update")
    run(*args)


def main() -> None:
    if os.geteuid() == 0:
        sys.exit("setup_user.py must run as the target user, not root")

    LOCAL_BIN.mkdir(parents=True, exist_ok=True)
    NODE_ROOT.parent.mkdir(parents=True, exist_ok=True)

    zipget = install_zipget()
    install_recipe_tools(zipget)

    with tempfile.TemporaryDirectory(prefix="linux-vibe-setup-") as temp_name:
        install_node(Path(temp_name))

    path = f"{LOCAL_BIN}:{NODE_ROOT / 'bin'}:{os.environ.get('PATH', '')}"
    npm_env = {**os.environ, "PATH": path, "npm_config_prefix": str(HOME / ".local")}
    run("npm", "config", "set", "prefix", str(HOME / ".local"), env=npm_env)
    run(
        "npm",
        "install",
        "--global",
        "@anthropic-ai/claude-code",
        "@github/copilot",
        env=npm_env,
    )

    log("installing uv and uvx with pipx")
    run("pipx", "install", "--force", "uv")

    log("user setup complete; authenticate claude, copilot, and gh interactively")


if __name__ == "__main__":
    main()
