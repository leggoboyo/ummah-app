#!/usr/bin/env python3
"""Estimate Cloudflare free-tier breakpoints for Ummah App remote Hadith packs."""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = REPO_ROOT / "features" / "hadith" / "dist" / "packs" / "manifest.json"

WORKERS_FREE_REQUESTS_PER_DAY = 100_000
KV_FREE_READS_PER_DAY = 100_000
KV_FREE_WRITES_PER_DAY = 1_000
R2_FREE_STORAGE_GB_MONTH = 10
R2_FREE_CLASS_A_PER_MONTH = 1_000_000
R2_FREE_CLASS_B_PER_MONTH = 10_000_000
STARTER_CLAIMS_DAILY_BUDGET = 400


def main() -> int:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    packs = manifest.get("packs", [])
    total_bytes = sum(int(pack.get("pack_size_bytes", 0)) for pack in packs)
    total_mb = total_bytes / 1_000_000
    total_mib = total_bytes / (1024 * 1024)

    fresh_install_worker_requests = 3
    fresh_install_kv_reads = 1
    fresh_install_kv_writes = 2  # starter-claim record + daily budget counter
    fresh_install_r2_class_b = 1

    theoretical_by_workers = WORKERS_FREE_REQUESTS_PER_DAY // fresh_install_worker_requests
    theoretical_by_kv_reads = KV_FREE_READS_PER_DAY // fresh_install_kv_reads
    theoretical_by_kv_writes = KV_FREE_WRITES_PER_DAY // fresh_install_kv_writes

    print("# Cloudflare Cost Breakpoints")
    print()
    print(f"Current uploaded Hadith pack storage: {total_mb:.2f} MB ({total_mib:.2f} MiB)")
    print(f"Stored packs: {len(packs)}")
    print()
    print("Free-tier limits used for this estimate:")
    print(f"- Workers Free requests/day: {WORKERS_FREE_REQUESTS_PER_DAY:,}")
    print(f"- KV reads/day: {KV_FREE_READS_PER_DAY:,}")
    print(f"- KV writes/day: {KV_FREE_WRITES_PER_DAY:,}")
    print(f"- R2 Standard storage/month: {R2_FREE_STORAGE_GB_MONTH} GB")
    print(f"- R2 Class A ops/month: {R2_FREE_CLASS_A_PER_MONTH:,}")
    print(f"- R2 Class B ops/month: {R2_FREE_CLASS_B_PER_MONTH:,}")
    print()
    print("Approximate free-user starter-pack install costs per new user:")
    print(f"- Worker requests: {fresh_install_worker_requests}")
    print(f"- KV reads: {fresh_install_kv_reads}")
    print(f"- KV writes: {fresh_install_kv_writes}")
    print(f"- R2 Class B ops: {fresh_install_r2_class_b}")
    print()
    print("Theoretical daily ceilings before free-tier pressure:")
    print(f"- Workers request ceiling: ~{theoretical_by_workers:,} new installs/day")
    print(f"- KV read ceiling: ~{theoretical_by_kv_reads:,} new installs/day")
    print(f"- KV write ceiling: ~{theoretical_by_kv_writes:,} new installs/day")
    print()
    print("Configured safety guardrail:")
    print(
        f"- STARTER_CLAIMS_DAILY_BUDGET is set to {STARTER_CLAIMS_DAILY_BUDGET:,} new starter claims/day"
    )
    print(
        "- This intentionally fails closed before the KV free write ceiling is silently exhausted."
    )
    print()
    print("Interpretation:")
    print("- R2 storage is not the practical bottleneck at the current pack size.")
    print("- Workers requests are not the first bottleneck for early-stage usage.")
    print("- KV writes/day are the first meaningful free-tier ceiling for the starter-pack claim design.")
    print(
        "- Paid extra-language packs still require the REVENUECAT_API_KEY Worker secret to be usable."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
