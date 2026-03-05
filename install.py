#!/usr/bin/env python3
"""Initialize environment by symlinking dotfiles."""

import sys
from pathlib import Path

DOTFILES_DIR = Path(__file__).parent.resolve()
HOME = Path.home()

SYMLINKS_LINUX = [
    # (source in dotfiles, target in home)
    ("tmux.conf", ".tmux.conf"),
    ("yazi", ".config/yazi"),
    ("lf", ".config/lf"),
]

SYMLINKS_WINDOWS = [
    # (source in dotfiles, target in home)
    ("yazi-win", "AppData/Roaming/yazi/config"),
    ("lf", "AppData/Roaming/lf"),
]


def create_symlink(source: str, target: str) -> None:
    src = DOTFILES_DIR / source
    dst = HOME / target

    if not src.exists():
        print(f"  SKIP: {source} (source not found)")
        return

    if dst.is_symlink():
        if dst.resolve() == src:
            print(f"  OK: {target} (already linked)")
            return
        dst.unlink()
    elif dst.exists():
        backup = dst.with_suffix(dst.suffix + ".bak")
        dst.rename(backup)
        print(f"  BACKUP: {target} -> {backup.name}")

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.symlink_to(src)
    print(f"  LINK: {target} -> {source}")


def main() -> None:
    print(f"Dotfiles: {DOTFILES_DIR}")
    print(f"Home: {HOME}\n")

    symlinks = SYMLINKS_WINDOWS if sys.platform == "win32" else SYMLINKS_LINUX
    for source, target in symlinks:
        create_symlink(source, target)

    print("\nDone.")


if __name__ == "__main__":
    main()
