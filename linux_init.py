#!/usr/bin/env python3
"""Initialize Linux environment by symlinking dotfiles."""

from pathlib import Path

DOTFILES_DIR = Path(__file__).parent.resolve()
HOME = Path.home()

SYMLINKS = [
    # (source in dotfiles, target in home)
    ("tmux.conf", ".tmux.conf"),
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

    dst.symlink_to(src)
    print(f"  LINK: {target} -> {source}")


def main() -> None:
    print(f"Dotfiles: {DOTFILES_DIR}")
    print(f"Home: {HOME}\n")

    for source, target in SYMLINKS:
        create_symlink(source, target)

    print("\nDone.")


if __name__ == "__main__":
    main()
