# Atlas Runbooks

This file is for website or account steps that Codex cannot finish alone.

Use these prompts in Atlas agentic mode. Each prompt is designed to run
autonomously and stop only for required human login or approval.

## RevenueCat Live Billing Setup

Use this when the app is ready for internal store testing and you have the
required Apple and Google credentials.

```text
Set up RevenueCat for the Ummah App mobile project as autonomously as possible.

Context:
- App name: Ummah App
- Bundle/package ID: com.zokorp.ummah
- Billing strategy: mixed model
- Free core stays free: prayer times, adhan notifications, minimal qibla, Hijri date, basic Quran reader
- Paid entitlements to create:
  - core_free
  - quran_plus
  - hadith_plus
  - ai_quran
  - ai_hadith
  - scholar_feed
  - mega_bundle
- Product IDs already aligned in code:
  - quran_plus_addon
  - hadith_plus_addon
  - ai_quran_monthly:monthly
  - ai_hadith_monthly:monthly
  - scholar_feed_monthly:monthly
  - mega_bundle_monthly:monthly

Your job:
1. Open RevenueCat and create the project for this app if it does not already exist.
2. Add both apps/platforms:
   - iOS app with bundle ID com.zokorp.ummah
   - Android app with package ID com.zokorp.ummah
3. Create the entitlements listed above.
4. Create products and map them to the correct entitlements.
5. Use a sensible default offering structure for launch:
   - individual products
   - one featured bundle
6. Capture and return:
   - RevenueCat project ID/name
   - iOS public SDK key
   - Android public SDK key
   - entitlement IDs
   - offering ID(s)
   - exact product IDs created/mapped
   - any configuration choices you made
7. If App Store Connect or Google Play Console product creation/login is required, stop only for that human intervention and tell me exactly what login or approval is needed.
8. Do not invent pricing without asking. If pricing is required, propose recommended defaults and wait for confirmation.
9. Give me a final clean summary I can hand back to Codex so it can wire the live RevenueCat SDK next.

Preferred behavior:
- Be autonomous
- Only stop for required human login/approval
- Avoid unnecessary questions
- Preserve the exact entitlement and product IDs above unless blocked
```

## App Store Connect API Key For RevenueCat

Use this when Atlas needs the Apple `.p8` subscription key, key ID, and issuer
ID for RevenueCat.

```text
Create the App Store Connect API credentials needed for RevenueCat integration for Ummah App.

Context:
- App bundle ID: com.zokorp.ummah
- Goal: generate the App Store Connect API key artifacts needed by RevenueCat
- I am non-technical, so make the process as autonomous as possible

Your job:
1. Open App Store Connect and navigate to the API keys area for integrations.
2. If an appropriate key already exists and is safe to reuse for RevenueCat, identify it instead of creating a duplicate.
3. If a new key is needed, create it with the minimum permissions required for RevenueCat subscription integration.
4. Download the `.p8` key file if Apple only allows one download.
5. Capture and return:
   - key name
   - key ID
   - issuer ID
   - exact access level/role granted
   - where the downloaded `.p8` file was saved
6. Do not expose the private key contents in chat.
7. If Apple requires human verification, password, or 2FA approval, stop only at that point and say exactly what approval is needed.
8. Give me a clean handoff summary I can provide to Codex and RevenueCat setup.

Preferred behavior:
- Avoid creating duplicate credentials unless necessary
- Choose the safest reusable option
- Stop only for required login or 2FA
```

## Google Play Service Account For RevenueCat

Use this when Atlas needs the Android service-account JSON for RevenueCat.

```text
Create the Google Play Console service account setup needed for RevenueCat integration for Ummah App.

Context:
- Android package ID: com.zokorp.ummah
- Goal: create or identify the least-privilege service account and JSON key needed by RevenueCat
- I am non-technical, so make the process as autonomous as possible

Your job:
1. Open Google Play Console and Google Cloud Console for the app/project tied to com.zokorp.ummah.
2. If a suitable existing service account already exists and is safe to reuse, identify it instead of creating a duplicate.
3. If a new one is needed, create a least-privilege service account appropriate for RevenueCat subscription syncing.
4. Generate the JSON key only if required.
5. Make the required Play Console permission assignment to that service account.
6. Capture and return:
   - service account email
   - project name or project ID
   - exact roles/permissions granted
   - where the JSON key file was saved
7. Do not paste private key contents in chat.
8. If Google requires human login, 2FA, or approval, stop only at that point and say exactly what is needed.
9. Give me a clean handoff summary I can provide to Codex and RevenueCat setup.

Preferred behavior:
- Avoid duplicate service accounts unless necessary
- Use least privilege
- Stop only for required login or approval
```

## HadeethEnc Compliance Check

Use this when we want to confirm versioning, rate limits, and attribution terms.

```text
Verify the public reuse/compliance details for HadeethEnc for the Ummah App project.

Goals:
- confirm whether HadeethEnc exposes a content or translation version beyond API/v1
- confirm whether there are documented rate limits or quotas
- confirm the exact attribution wording required for app reuse
- find the best official contact path if the public docs do not answer these questions

Your job:
1. Open the official HadeethEnc site and official API docs.
2. Search specifically for:
   - version
   - update
   - rate limit
   - quota
   - attribution
   - terms
   - API usage
3. Inspect the docs for:
   - GET /api/v1/languages
   - GET /api/v1/categories/roots
   - GET /api/v1/hadeeths/list
   - GET /api/v1/hadeeths/one
4. If the answer is not in the docs, inspect the official site for terms, footer notes, contact, or about pages.
5. Return a final report with:
   - versioning details found
   - rate limit details found
   - attribution wording found
   - official contact URL or email
   - any unresolved gaps
6. Stop only if login is unexpectedly required.
```

## IslamHouse API Expansion Check

Use this later only if we want to go beyond public RSS and integrate an
authenticated IslamHouse API.

```text
Research the official IslamHouse API options for Ummah App and determine whether we should upgrade beyond public RSS feeds.

Context:
- Current app implementation already uses public IslamHouse RSS feeds successfully
- We only want an authenticated API if it gives meaningful business value over RSS
- We want low friction, low cost, and clear terms

Your job:
1. Find the official IslamHouse API documentation, signup path, and any app-key requirements.
2. Confirm what the API adds beyond RSS:
   - richer metadata
   - filtering
   - pagination
   - localization
   - content bodies
   - rate limits
3. Confirm whether public use requires registration, approval, or credentials.
4. Capture:
   - official docs URL
   - signup URL
   - auth method
   - rate limits or quotas
   - terms or attribution requirements
   - whether it is worth integrating in v1 compared to RSS
5. Give a final recommendation in non-technical terms:
   - stay on RSS for now
   - upgrade to API now
   - revisit later
6. Stop only for required human login or approval.
```
