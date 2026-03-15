#!/usr/bin/env python3
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACK_PATHS = sorted(ROOT.glob("features/*/packs/*.json"))
DOCS_DIR = ROOT / "docs" / "sources"
PACK_DOCS_DIR = DOCS_DIR / "packs"
APP_CATALOG_PATH = ROOT / "mobile" / "app" / "assets" / "generated" / "source_catalog.json"


def load_manifests() -> list[dict]:
    manifests = []
    for path in PACK_PATHS:
        manifest = json.loads(path.read_text(encoding="utf-8"))
        manifest["_repo_path"] = str(path.relative_to(ROOT))
        manifests.append(manifest)
    manifests.sort(key=lambda item: item["pack_id"])
    return manifests


def write_pack_docs(manifests: list[dict]) -> None:
    PACK_DOCS_DIR.mkdir(parents=True, exist_ok=True)
    for manifest in manifests:
        pack_id = manifest["pack_id"]
        output = PACK_DOCS_DIR / f"{pack_id.replace(':', '__')}.md"
        lines = [
            f"# {manifest['title']}",
            "",
            f"- Pack ID: `{pack_id}`",
            f"- Module ID: `{manifest['module_id']}`",
            f"- Version: `{manifest['version']}`",
            f"- Delivery: `{manifest['delivery_type']}`",
            f"- Content type: `{manifest['content_type']}`",
            f"- Locales: {', '.join(manifest['locales'])}",
            f"- Size: `{manifest['size_bytes']}` bytes",
            f"- SHA-256: `{manifest['sha256']}`",
            f"- Repo manifest: `{manifest['_repo_path']}`",
            "",
            manifest["summary"],
            "",
            "## Install steps",
        ]
        lines.extend([f"- {step}" for step in manifest["install_steps"]])
        lines.extend(["", "## Compatibility"])
        lines.extend([f"- {item}" for item in manifest["compatibility"]])
        if manifest.get("artifact_path"):
            lines.extend(["", f"- Artifact path: `{manifest['artifact_path']}`"])
        if manifest.get("remote_object_key"):
            lines.extend([f"- Remote object key: `{manifest['remote_object_key']}`"])
        if manifest.get("required_entitlement_key"):
            lines.extend(
                [f"- Required entitlement key: `{manifest['required_entitlement_key']}`"]
            )
        lines.extend(["", "## Sources"])
        for source in manifest["sources"]:
            lines.extend(
                [
                    f"### {source['name']}",
                    "",
                    f"- URL: {source['url']}",
                    f"- Version: `{source['version']}`",
                    f"- License summary: {source['license_summary']}",
                    f"- Attribution required: `{str(source['attribution_required']).lower()}`",
                    f"- No modify required: `{str(source['no_modify_required']).lower()}`",
                    f"- Verbatim only: `{str(source['verbatim_only']).lower()}`",
                    "",
                ]
            )
        output.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")


def write_index(manifests: list[dict]) -> None:
    grouped: dict[str, list[dict]] = defaultdict(list)
    for manifest in manifests:
        grouped[manifest["module_id"]].append(manifest)

    lines = [
        "# Sources",
        "",
        "This directory is generated from canonical feature-local pack manifests. It documents shipped or planned pack artifacts with attribution, versioning, and licensing notes.",
        "",
    ]
    for module_id in sorted(grouped):
        lines.append(f"## `{module_id}`")
        lines.append("")
        for manifest in grouped[module_id]:
            file_name = f"{manifest['pack_id'].replace(':', '__')}.md"
            lines.append(
                f"- [{manifest['title']}](packs/{file_name}) — `{manifest['version']}`"
            )
        lines.append("")

    (DOCS_DIR / "index.md").write_text("\n".join(lines).strip() + "\n", encoding="utf-8")


def write_app_catalog(manifests: list[dict]) -> None:
    APP_CATALOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "generated_label": "Bundled with this build from canonical feature-local pack manifests.",
        "packs": [
            {key: value for key, value in manifest.items() if not key.startswith("_")}
            for manifest in manifests
        ],
    }
    APP_CATALOG_PATH.write_text(
        json.dumps(payload, indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    manifests = load_manifests()
    if not manifests:
        raise SystemExit("No canonical pack manifests found.")
    write_pack_docs(manifests)
    write_index(manifests)
    write_app_catalog(manifests)
    print(
        f"Generated source docs for {len(manifests)} pack(s) and app catalog at {APP_CATALOG_PATH.relative_to(ROOT)}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
