#!/usr/bin/env python3
from __future__ import annotations

import os
import pathlib
import re
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]

FORBIDDEN_FILE_PATTERNS = (
    re.compile(r"(^|/)\.env(\..+)?$"),
    re.compile(r"(^|/)\.dev\.vars(\..+)?$"),
    re.compile(r"\.(pem|p12|mobileprovision|jks|keystore)$"),
)

HIGH_CONFIDENCE_SECRET_PATTERNS = (
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"sk_(?:live|test|proj)_[A-Za-z0-9]{12,}"),
)

SKIP_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".ico",
    ".pdf",
    ".aab",
    ".apk",
    ".zip",
    ".gz",
    ".sqlite",
    ".db",
    ".bin",
    ".jar",
    ".class",
}


def tracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    return [path for path in result.stdout.decode("utf-8").split("\0") if path]


def is_probably_binary(path: pathlib.Path) -> bool:
    if path.suffix.lower() in SKIP_EXTENSIONS:
        return True
    try:
        with path.open("rb") as handle:
            chunk = handle.read(1024)
    except OSError:
        return False
    return b"\0" in chunk


def main() -> int:
    failures: list[str] = []

    for relative in tracked_files():
        for pattern in FORBIDDEN_FILE_PATTERNS:
            if pattern.search(relative):
                failures.append(f"Tracked secret-like file path: {relative}")
                break

        absolute = ROOT / relative
        if not absolute.is_file() or is_probably_binary(absolute):
            continue

        try:
            text = absolute.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for pattern in HIGH_CONFIDENCE_SECRET_PATTERNS:
            if pattern.search(text):
                failures.append(
                    f"High-confidence secret pattern found in {relative}: {pattern.pattern}"
                )

    if failures:
        for failure in failures:
            print(failure)
        return 1

    print("No tracked secret files or high-confidence secret patterns found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
