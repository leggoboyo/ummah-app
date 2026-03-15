#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FEATURES_DIR = ROOT / "features"
IMPORT_RE = re.compile(r"import\s+'package:([a-zA-Z0-9_]+)/")


def main() -> int:
    errors: list[str] = []
    feature_names = {p.name for p in FEATURES_DIR.iterdir() if p.is_dir()}
    for feature_dir in sorted(p for p in FEATURES_DIR.iterdir() if p.is_dir()):
        feature_name = feature_dir.name
        for file_path in sorted(feature_dir.rglob("*.dart")):
            if ".dart_tool" in file_path.parts or "build" in file_path.parts:
                continue
            text = file_path.read_text(encoding="utf-8")
            for match in IMPORT_RE.finditer(text):
                imported = match.group(1)
                if imported == feature_name:
                    continue
                if imported in {"core", "flutter", "flutter_test", "test"}:
                    continue
                if imported in feature_names:
                    errors.append(
                        f"{file_path.relative_to(ROOT)} imports feature package "
                        f"'{imported}', which violates the app-shell composition boundary."
                    )

    if errors:
        print("Feature boundary check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Feature boundary check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
