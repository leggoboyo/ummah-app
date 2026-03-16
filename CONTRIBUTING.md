# Contributing

Thanks for contributing to Ummah App.

This repository is public because the project is trying to make its privacy,
offline, and sourcing claims inspectable in code. Contributions should support
that goal, not weaken it.

## Ground rules

- The free core should stay offline-first.
- Do not add analytics, telemetry, or hidden backend dependencies to the free
  core.
- Do not require an app account for the free core.
- Keep source attribution visible and do not rewrite canonical Quran text or
  source-backed hadith text for display.
- Prefer simple, auditable implementations over clever opaque ones.

## Local setup

From the repository root:

```bash
make bootstrap
```

Common commands:

```bash
make analyze
make test
make worker-test
make secret-scan
make size-report
make android-smoke
make site-preview
```

If you need a lower-end Android emulator profile:

```bash
make create-low-end-avd
```

## Branch and PR expectations

- Create branches from `main`.
- Use a `codex/` branch prefix for implementation branches.
- Open a pull request instead of pushing directly to `main`.
- Expect `main` to require:
  - one approval
  - passing required checks

Current required checks include:

- `android-build-size`
- `analyze-and-test`
- `build-android`
- `build-ios`
- `format-and-worker`
- `dependency-audit / osv-scan`
- `secret-scan`
- `workflow-lint`

## Formatting and test expectations

Before opening or updating a PR, run:

```bash
dart format .
make analyze
make test
make worker-test
make secret-scan
```

If your change affects release posture or Android artifact size, also run:

```bash
make size-report
```

If your change affects startup, onboarding, or low-end Android behavior, also
run:

```bash
make android-smoke
```

## What to include in a PR

Please summarize:

- what changed
- why it changed
- how you verified it
- any remaining risks or manual follow-up

If a change affects privacy, security, licensing, release posture, or the trust
site, update the relevant docs in the same PR.
