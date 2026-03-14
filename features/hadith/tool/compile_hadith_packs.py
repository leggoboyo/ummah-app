#!/usr/bin/env python3
"""Compile official HadeethEnc XLSX downloads into remote-delivery pack artifacts."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Iterable
from zipfile import ZipFile

NS = {"x": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}

DEFAULT_LANGS = ("en", "ar", "ur")
LANGUAGE_NAMES = {
    "en": "English",
    "ar": "Arabic",
    "ur": "Urdu",
}


@dataclass(frozen=True)
class DownloadTarget:
    language_code: str
    version: str
    download_url: str
    temp_path: Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--languages",
        nargs="+",
        default=list(DEFAULT_LANGS),
        help="Language codes to compile, e.g. en ar ur",
    )
    parser.add_argument(
        "--out-dir",
        default="features/hadith/dist/packs",
        help="Directory where manifest and upload-ready pack files are written",
    )
    parser.add_argument(
        "--manifest-url",
        default="",
        help="Public manifest URL to embed in manifest entries once deployed",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[3]
    out_dir = repo_root / args.out_dir
    temp_dir = repo_root / ".dart_tool" / "hadith_pack_tmp"
    out_dir.mkdir(parents=True, exist_ok=True)
    temp_dir.mkdir(parents=True, exist_ok=True)
    objects_dir = out_dir / "objects"
    objects_dir.mkdir(parents=True, exist_ok=True)

    manifests = []
    for language_code in args.languages:
        target = resolve_download(language_code, temp_dir)
        manifest = compile_language_pack(
            language_code=target.language_code,
            language_name=LANGUAGE_NAMES.get(
                target.language_code,
                target.language_code,
            ),
            version=target.version,
            download_url=target.download_url,
            source_url=f"https://hadeethenc.com/{target.language_code}/home",
            xlsx_path=target.temp_path,
            objects_dir=objects_dir,
            manifest_url=args.manifest_url,
        )
        manifests.append(manifest)

    manifest_doc = {
        "provider_key": "hadeethenc",
        "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "packs": manifests,
    }
    manifest_path = out_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest_doc, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {manifest_path}")
    return 0


def resolve_download(language_code: str, temp_dir: Path) -> DownloadTarget:
    url = f"https://hadeethenc.com/browse/download/{language_code}"
    opener = urllib.request.build_opener()
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "UmmahAppPackCompiler/1.0"},
    )
    with opener.open(request, timeout=60) as response:
        download_url = response.geturl()
        content = response.read()

    match = re.search(rf"_{re.escape(language_code)}-v([0-9.]+)\.xlsx$", download_url)
    if not match:
        raise SystemExit(f"Could not determine version from {download_url}")

    temp_path = temp_dir / f"{language_code}.xlsx"
    temp_path.write_bytes(content)
    return DownloadTarget(
        language_code=language_code,
        version=match.group(1),
        download_url=download_url,
        temp_path=temp_path,
    )


def compile_language_pack(
    *,
    language_code: str,
    language_name: str,
    version: str,
    download_url: str,
    source_url: str,
    xlsx_path: Path,
    objects_dir: Path,
    manifest_url: str,
) -> dict:
    rows, last_updated_at = read_hadeethenc_xlsx(xlsx_path)
    object_key = f"hadith/{language_code}/v{version}/pack.json.gz"
    pack_path = objects_dir / object_key
    pack_path.parent.mkdir(parents=True, exist_ok=True)

    payload = {
        "provider_key": "hadeethenc",
        "language_code": language_code,
        "language_name": language_name,
        "version": version,
        "source_url": source_url,
        "download_url": download_url,
        "last_updated_at": last_updated_at,
        "records": rows,
    }
    pack_bytes = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode(
        "utf-8"
    )
    gz_bytes = gzip.compress(pack_bytes, compresslevel=9)
    pack_path.write_bytes(gz_bytes)

    file_hash = hashlib.sha256(gz_bytes).hexdigest()
    manifest = {
        "provider_key": "hadeethenc",
        "pack_id": f"hadith_pack:{language_code}",
        "module": "hadithPack",
        "language_code": language_code,
        "language_name": language_name,
        "version": version,
        "source_url": source_url,
        "download_url": "",
        "object_key": object_key,
        "file_hash": file_hash,
        "record_count": len(rows),
        "pack_size_bytes": len(gz_bytes),
        "last_updated_at": last_updated_at,
        "is_starter_free_eligible": True,
        "manifest_url": manifest_url,
        "required_entitlement_key": "hadith_plus",
        "is_bundled": False,
    }
    print(f"Wrote {pack_path} ({len(rows)} hadith)")
    return manifest


def read_hadeethenc_xlsx(xlsx_path: Path) -> tuple[list[dict], str]:
    with ZipFile(xlsx_path) as zf:
        shared_strings = load_shared_strings(zf)
        rows = list(read_rows(zf, shared_strings))

    if len(rows) < 3:
        raise SystemExit(f"Unexpected workbook format in {xlsx_path}")

    metadata = rows[0][0] if rows[0] else ""
    last_updated_at = parse_last_updated(metadata)
    header = rows[1]
    header_index = {name: idx for idx, name in enumerate(header)}
    bilingual_required = [
        "id",
        "title_ar",
        "title",
        "hadith_text_ar",
        "hadith_text",
        "explanation_ar",
        "explanation",
        "benefits_ar",
        "benefits",
        "grade_ar",
        "takhrij_ar",
        "grade",
        "takhrij",
        "lang",
        "link",
    ]
    arabic_required = [
        "id",
        "title",
        "hadith_text",
        "explanation",
        "word_meanings",
        "benefits",
        "grade",
        "takhrij",
        "link",
    ]
    if all(name in header_index for name in bilingual_required):
        workbook_kind = "bilingual"
    elif all(name in header_index for name in arabic_required):
        workbook_kind = "arabic"
    else:
        raise SystemExit(
            f"Missing expected columns in {xlsx_path}: {sorted(header_index.keys())}"
        )

    records = []
    for values in rows[2:]:
        if not values or not cell(values, header_index, "id").strip():
            continue
        hadith_id = int(cell(values, header_index, "id"))
        if workbook_kind == "arabic":
            title = cell(values, header_index, "title").strip()
            hadith_text = cell(values, header_index, "hadith_text").strip()
            explanation = cell(values, header_index, "explanation").strip()
            benefits = split_lines(cell(values, header_index, "benefits"))
            words_meanings = split_lines(cell(values, header_index, "word_meanings"))
            grade = cell(values, header_index, "grade").strip()
            source_reference = cell(values, header_index, "takhrij").strip()
            record = {
                "id": hadith_id,
                "language_code": "ar",
                "title_arabic": title,
                "title": title,
                "hadith_text_arabic": hadith_text,
                "hadith_text": hadith_text,
                "explanation_arabic": explanation,
                "explanation": explanation,
                "benefits_arabic": benefits,
                "benefits": benefits,
                "grade_arabic": grade,
                "source_reference_arabic": source_reference,
                "grade": grade,
                "source_reference": source_reference,
                "words_meanings_arabic": words_meanings,
                "source_url": cell(values, header_index, "link").strip(),
            }
        else:
            benefits = split_lines(cell(values, header_index, "benefits"))
            benefits_arabic = split_lines(cell(values, header_index, "benefits_ar"))
            record = {
                "id": hadith_id,
                "language_code": cell(values, header_index, "lang").strip() or "en",
                "title_arabic": cell(values, header_index, "title_ar").strip(),
                "title": cell(values, header_index, "title").strip(),
                "hadith_text_arabic": cell(
                    values,
                    header_index,
                    "hadith_text_ar",
                ).strip(),
                "hadith_text": cell(values, header_index, "hadith_text").strip(),
                "explanation_arabic": cell(
                    values,
                    header_index,
                    "explanation_ar",
                ).strip(),
                "explanation": cell(values, header_index, "explanation").strip(),
                "benefits_arabic": benefits_arabic,
                "benefits": benefits,
                "grade_arabic": cell(values, header_index, "grade_ar").strip(),
                "source_reference_arabic": cell(
                    values,
                    header_index,
                    "takhrij_ar",
                ).strip(),
                "grade": cell(values, header_index, "grade").strip(),
                "source_reference": cell(values, header_index, "takhrij").strip(),
                "words_meanings_arabic": [],
                "source_url": cell(values, header_index, "link").strip(),
            }
        records.append(record)
    return records, last_updated_at


def load_shared_strings(zf: ZipFile) -> list[str]:
    root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
    values = []
    for si in root.findall("x:si", NS):
        texts = [t.text or "" for t in si.iter("{%s}t" % NS["x"])]
        values.append("".join(texts))
    return values


def read_rows(zf: ZipFile, shared_strings: list[str]) -> Iterable[list[str]]:
    sheet = ET.fromstring(zf.read("xl/worksheets/sheet1.xml"))
    sheet_data = sheet.find("x:sheetData", NS)
    if sheet_data is None:
        return []

    for row in sheet_data.findall("x:row", NS):
        cells = []
        for cell in row.findall("x:c", NS):
            cell_type = cell.attrib.get("t")
            value_node = cell.find("x:v", NS)
            if value_node is None or value_node.text is None:
                cells.append("")
                continue
            value = value_node.text
            if cell_type == "s":
                cells.append(shared_strings[int(value)])
            else:
                cells.append(value)
        yield cells


def parse_last_updated(metadata: str) -> str:
    match = re.search(r"Last update:\s*([0-9:\- ]+)\s+\(v[0-9.]+\)", metadata)
    if not match:
        return ""
    raw = match.group(1).strip()
    return datetime.strptime(raw, "%Y-%m-%d %H:%M:%S").isoformat()


def split_lines(value: str) -> list[str]:
    return [line.strip() for line in value.splitlines() if line.strip()]


def cell(values: list[str], header_index: dict[str, int], name: str) -> str:
    index = header_index[name]
    if index >= len(values):
        return ""
    return values[index]


if __name__ == "__main__":
    sys.exit(main())
