#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "docs" / "schemas" / "pack-manifest.schema.json"
PACK_GLOB = "features/*/packs/*.json"
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:[-+][0-9A-Za-z.-]+)?$")


def load_schema() -> dict:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def find_manifest_paths() -> list[Path]:
    return sorted(ROOT.glob(PACK_GLOB))


def validate_required_keys(manifest: dict, schema: dict, path: Path, errors: list[str]) -> None:
    for key in schema["required"]:
        if key not in manifest:
            errors.append(f"{path.relative_to(ROOT)} is missing required key '{key}'.")
    for key in manifest:
        if key not in schema["properties"]:
            errors.append(f"{path.relative_to(ROOT)} has unsupported key '{key}'.")


def validate_manifest(manifest: dict, path: Path, schema: dict, seen_pack_ids: set[str], errors: list[str]) -> None:
    validate_required_keys(manifest, schema, path, errors)
    pack_id = manifest.get("pack_id", "")
    if not isinstance(pack_id, str) or not re.match(schema["properties"]["pack_id"]["pattern"], pack_id):
        errors.append(f"{path.relative_to(ROOT)} has an invalid pack_id.")
    elif pack_id in seen_pack_ids:
        errors.append(f"Duplicate pack_id '{pack_id}' found in {path.relative_to(ROOT)}.")
    else:
        seen_pack_ids.add(pack_id)

    version = manifest.get("version", "")
    if not isinstance(version, str) or not SEMVER_RE.match(version):
        errors.append(f"{path.relative_to(ROOT)} version '{version}' is not valid semver.")

    sha256 = manifest.get("sha256", "")
    if not isinstance(sha256, str) or not re.fullmatch(r"[a-f0-9]{64}", sha256):
        errors.append(f"{path.relative_to(ROOT)} has an invalid sha256 value.")

    for enum_key in ("content_type", "delivery_type"):
        allowed = set(schema["properties"][enum_key]["enum"])
        if manifest.get(enum_key) not in allowed:
            errors.append(
                f"{path.relative_to(ROOT)} has invalid {enum_key} '{manifest.get(enum_key)}'."
            )

    locales = manifest.get("locales", [])
    if not isinstance(locales, list) or not locales:
        errors.append(f"{path.relative_to(ROOT)} must declare at least one locale.")

    sources = manifest.get("sources", [])
    if not isinstance(sources, list) or not sources:
        errors.append(f"{path.relative_to(ROOT)} must declare at least one source entry.")
    else:
        required_source_keys = schema["properties"]["sources"]["items"]["required"]
        for index, source in enumerate(sources):
            if not isinstance(source, dict):
                errors.append(f"{path.relative_to(ROOT)} source #{index + 1} is not an object.")
                continue
            for key in required_source_keys:
                if key not in source:
                    errors.append(
                        f"{path.relative_to(ROOT)} source #{index + 1} is missing '{key}'."
                    )

    artifact_path = manifest.get("artifact_path")
    if artifact_path:
        artifact = ROOT / artifact_path
        if not artifact.exists():
            errors.append(f"{path.relative_to(ROOT)} references missing artifact_path '{artifact_path}'.")
        else:
            actual_hash = hashlib.sha256(artifact.read_bytes()).hexdigest()
            if actual_hash != sha256:
                errors.append(
                    f"{path.relative_to(ROOT)} sha256 does not match artifact_path '{artifact_path}'."
                )
            actual_size = artifact.stat().st_size
            if actual_size != manifest.get("size_bytes"):
                errors.append(
                    f"{path.relative_to(ROOT)} size_bytes {manifest.get('size_bytes')} does not match artifact size {actual_size}."
                )


def _load_json_from_git(ref: str, relative_path: str) -> dict | None:
    result = subprocess.run(
        ["git", "show", f"{ref}:{relative_path}"],
        capture_output=True,
        text=True,
        cwd=ROOT,
    )
    if result.returncode != 0:
        return None
    return json.loads(result.stdout)


def _semver_tuple(value: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(value)
    if not match:
        raise ValueError(value)
    return tuple(int(group) for group in match.groups()[:3])  # type: ignore[return-value]


def validate_version_bumps(paths: list[Path], base_ref: str, errors: list[str]) -> None:
    diff = subprocess.run(
        ["git", "diff", "--name-only", base_ref, "--", PACK_GLOB],
        capture_output=True,
        text=True,
        cwd=ROOT,
    )
    if diff.returncode != 0:
        errors.append(f"Unable to diff pack manifests against {base_ref}.")
        return

    changed = {line.strip() for line in diff.stdout.splitlines() if line.strip()}
    for path in paths:
        relative_path = str(path.relative_to(ROOT))
        if relative_path not in changed:
            continue
        current = json.loads(path.read_text(encoding="utf-8"))
        previous = _load_json_from_git(base_ref, relative_path)
        if previous is None:
            continue
        if current == previous:
            continue
        if current.get("version") == previous.get("version"):
            errors.append(
                f"{relative_path} changed relative to {base_ref} without a version bump."
            )
            continue
        try:
            if _semver_tuple(current["version"]) <= _semver_tuple(previous["version"]):
                errors.append(
                    f"{relative_path} version {current['version']} must be greater than {previous['version']}."
                )
        except Exception:
            errors.append(f"{relative_path} has a non-comparable semver bump.")


def main(argv: list[str]) -> int:
    base_ref = "origin/main"
    check_version_bumps = False
    if "--check-version-bumps" in argv:
        check_version_bumps = True
    if "--base-ref" in argv:
        index = argv.index("--base-ref")
        base_ref = argv[index + 1]

    schema = load_schema()
    paths = find_manifest_paths()
    errors: list[str] = []
    seen_pack_ids: set[str] = set()

    if not paths:
        errors.append("No feature-local pack manifests were found.")

    for path in paths:
        manifest = json.loads(path.read_text(encoding="utf-8"))
        validate_manifest(manifest, path, schema, seen_pack_ids, errors)

    if check_version_bumps:
        validate_version_bumps(paths, base_ref, errors)

    if errors:
        print("Pack validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Validated {len(paths)} canonical pack manifest(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
