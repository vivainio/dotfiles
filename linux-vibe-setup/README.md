# linux-vibe-setup

Repeatable bootstrap for a native Ubuntu 24.04 coding-agent host. It provides
rootless Podman and installs AI command-line tools for each Unix user.
Derivatives that track the same package set are supported too: the system
script accepts any distribution reporting `UBUNTU_CODENAME=noble`, such as
Linux Mint 22.

The scripts are intentionally split by privilege:

- `setup_system.py` is run once as root. It installs Ubuntu packages and
  prepares named users for rootless Podman.
- `setup_user.py` is run once per user, as that user. It installs Node.js,
  Claude Code, GitHub Copilot CLI, and `uv` under the user's home directory.

Both scripts are safe to run again to repair or update a machine.
The container build reuses `setup_system.py --packages-only` so its shared
package set stays aligned without attempting host login-user configuration.

## Install

Clone or copy this repository onto the Ubuntu host. Run the system setup once,
then run the user setup separately from each account that will use the host:

```bash
sudo python3 setup_system.py
python3 setup_user.py
```

With no arguments, the system script configures all normal login users. It also
accepts explicit usernames (`sudo python3 setup_system.py alice bob`) when a
more selective run is useful.

After setup, start a fresh login session so that `~/.local/bin` is on `PATH`.
For additional users, run:

```bash
sudo python3 setup_system.py alice
sudo -iu alice
cd /path/to/linux-vibe-setup
python3 setup_user.py
```

Then authenticate interactively. Authentication is deliberately not part of
provisioning:

```bash
claude
copilot login
gh auth login
```

Useful checks:

```bash
python3 ./verify_user.py
podman run --rm docker.io/library/hello-world
```

## What is installed

System-wide Ubuntu packages include Git, Git LFS, GitHub CLI, build tools,
Python, common shell utilities, and the packages required by rootless
Podman. Docker is not installed and no Docker socket compatibility layer is
enabled.

Per user, the setup installs:

- `zipget`, bootstrapped from its official GitHub release, followed by every
  tool declared in `linux-tools.toml` (including AWS CLI, Herdr, CShip,
  starship, ripgrep, fd, bat, fzf, zoxide, and delta);
- the latest available Node.js 22 release, with its published SHA-256 checksum
  verified before extraction;
- Claude Code, using Anthropic's recommended native installer;
- GitHub Copilot CLI, using GitHub's native install script;
- Astral `uv` and `uvx`.

Both x86-64 and arm64 hosts are supported. `setup_user.py` detects the CPU and
passes the matching architecture names to the `linux-tools.toml` recipe, so the
tool set is identical on either.

Node 22 is installed as the general-purpose JavaScript runtime.
CShip is installed only; the setup does not create a CShip theme or modify
Claude Code's `statusLine` setting.

## Public-repository security

This repository contains no credentials or environment-specific identity.
The scripts do not accept or persist tokens. Keep authentication state in each
user's home directory and never copy it into this checkout.

Do not commit `.env` files, private keys, cloud credentials, or tool state such
as `.claude/` and `.copilot/`. The `.gitignore` provides a backstop, but it is
not a substitute for reviewing changes before a commit.
