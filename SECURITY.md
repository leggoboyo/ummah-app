# Security Policy

## Reporting a vulnerability

Please do not open public GitHub issues for security problems.

Preferred path:

- Use GitHub's private vulnerability reporting for this repository if the
  "Report a vulnerability" option is visible in the Security tab.

Fallback path:

- If private reporting is not available in the GitHub UI, email
  `zkhawaja721@gmail.com` with the subject line `Ummah App security report`.

When you report an issue, include:

- affected platform and app version
- reproduction steps
- whether the issue requires network access, billing, or a specific language pack
- whether the issue affects the free core, optional Cloudflare delivery, the
  trust site, or store billing

## Scope

Please report vulnerabilities related to:

- the mobile app in `mobile/app`
- shared packages in `packages/` and `features/`
- the optional Cloudflare Worker and content-pack delivery flow
- the public trust site in `website/`
- release, secret-handling, or CI/workflow issues that could affect users

Out of scope:

- general feature requests
- content disagreements that are not security issues
- issues that require physical access to an already-unlocked device with no
  additional privilege escalation

## Disclosure expectations

- Give the maintainer a reasonable chance to investigate and fix the issue
  before public disclosure.
- Avoid posting proof-of-concept details publicly until the issue is resolved
  or a coordinated disclosure date is agreed.
- If you are unsure whether something is a security issue, report it privately
  first.
