# Cloudflare Cost Model

This document explains the expected Cloudflare cost posture for Ummah App's
optional remote Hadith-pack delivery.

## Current optional infrastructure

- Worker: `ummah-content-pack-worker`
- R2 bucket: `ummah-content-packs`
- KV namespace: `ummah-starter-pack-claims`

Core app features do not depend on this infrastructure. It exists only for
optional remote Hadith packs.

## Current pack footprint

The current remote Hadith packs total about `9.27 MB` compressed across the
English, Arabic, and Urdu HadeethEnc packs. This is far below the R2 Standard
free storage tier.

## Real free-tier bottleneck

The first meaningful early-stage Cloudflare ceiling is not R2 storage.

It is **Workers KV writes/day**.

Why:
- each first-time free starter-pack claim writes a per-user claim record
- Ummah also writes a daily budget counter to fail closed before silent growth

That means each new free starter-pack claim uses approximately:
- `1` KV read
- `2` KV writes
- `3` Worker requests across manifest/access/download
- `1` R2 Class B read

## Guardrail in code

The Worker now enforces:

- `STARTER_CLAIMS_DAILY_BUDGET = 400`

This is intentionally conservative. It keeps the optional starter-pack service
well below the free KV write ceiling for early-stage usage.

If the service reaches that budget for the UTC day, new starter-pack claims
fail softly instead of continuing until billing or limits become surprising.

## Practical interpretation

- early family/internal testing: effectively `$0`
- small launch: likely `$0`
- storage is not the near-term cost risk
- the first scaling pressure is starter-pack claim volume

## How to re-check the estimate

Run:

```bash
python3 scripts/estimate_cloudflare_costs.py
```

That script reads the current Hadith manifest and prints the relevant free-tier
breakpoints and the configured daily safety budget.
