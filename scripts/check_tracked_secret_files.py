#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys


FORBIDDEN_PREFIXES = (
    ".env",
    ".dev.vars",
)

ALLOWED_SUFFIXES = (
    ".example",
    ".sample",
    ".template",
)


def main() -> int:
    result = subprocess.run(
        ["git", "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    offending = []
    for line in result.stdout.splitlines():
        name = line.rsplit("/", 1)[-1]
        if any(name.endswith(suffix) for suffix in ALLOWED_SUFFIXES):
            continue
        if any(
            name == prefix or name.startswith(f"{prefix}.")
            for prefix in FORBIDDEN_PREFIXES
        ):
            offending.append(line)

    if offending:
        print("Tracked secret-like files are not allowed:")
        for path in offending:
            print(f"- {path}")
        return 1

    print("Tracked secret-file check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
