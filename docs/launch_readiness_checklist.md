# Launch Readiness Checklist

## Free-core offline proof
- [ ] `make test` passes with:
  - `mobile/app/test/app_controller_offline_contract_test.dart`
  - `features/quran/test/quran_repository_test.dart`
- [ ] Free core still works with no backend:
  - prayer schedule
  - local adhan notifications
  - qibla bearing
  - Hijri date
  - Quran Arabic reading
- [ ] `apiBaseUrl` is optional and an empty value does not block startup

## Notification reliability
- [ ] iOS scheduling stays below the 64 pending local-notification cap
- [ ] iOS reminder copy explains that reminders are rolling and the app should be opened periodically
- [ ] Android exact alarms degrade cleanly to inexact reminders when permission is denied or revoked
- [ ] Android manifest still includes reboot rescheduling receiver for local prayer alerts

## Optional infrastructure boundaries
- [ ] Remote Hadith Worker is never required for prayer/qibla/Quran Arabic
- [ ] Signed Hadith pack download URLs are short-lived and redacted from logs
- [ ] Cloudflare `STARTER_CLAIMS_DAILY_BUDGET` remains below the free KV write ceiling with headroom
- [ ] Paid extra-language Hadith packs fail closed if RevenueCat Worker configuration is missing

## Billing and secrets hygiene
- [ ] No secret API keys appear in mobile env files
- [ ] `DOWNLOAD_SIGNING_SECRET` exists in Cloudflare Worker secrets
- [ ] `REVENUECAT_API_KEY` exists in Cloudflare Worker secrets before enabling paid remote Hadith language packs
- [ ] RevenueCat public SDK keys stay client-side only; secret keys stay server-side only

## Source attribution and versions
- [ ] HadeethEnc attribution and version metadata remain visible in the Hadith source/version surfaces
- [ ] Quran source/version metadata remains visible for bundled Arabic and downloaded translations
- [ ] No ads or unrelated monetization surfaces appear alongside republished Hadith/Quran content

## Atlas task
Use this only for the final required manual step:

```text
Add the missing RevenueCat Worker secret for Ummah App and verify the deployed Cloudflare Worker environment safely.

Context:
- Cloudflare account: Zkhawaja721@gmail.com’s Account
- Worker name: ummah-content-pack-worker
- Worker URL: https://ummah-content-pack-worker.zkhawaja721.workers.dev
- This Worker already has DOWNLOAD_SIGNING_SECRET configured.
- The remaining missing secret is REVENUECAT_API_KEY.
- The free starter-pack flow is already live.
- Paid extra-language Hadith pack access must stay disabled/unavailable until this secret is added correctly.

Goal:
1. Add REVENUECAT_API_KEY as a Cloudflare Worker secret.
2. Verify the Worker still deploys cleanly.
3. Confirm the secret exists without exposing its value in chat.
4. Confirm paid-pack authorization is now ready from the Cloudflare side.

Your job:
1. Open Cloudflare dashboard for the correct account.
2. Open Workers & Pages and select `ummah-content-pack-worker`.
3. Go to Settings / Variables / Secrets.
4. Add a new secret named `REVENUECAT_API_KEY`.
5. Use the real RevenueCat secret API key for the Ummah App project.
6. Save it without exposing the value anywhere in chat.
7. If Cloudflare requires redeploy or version promotion, do that.
8. Confirm back with:
   - whether the secret was added
   - whether the Worker needed redeploy
   - whether anything is still blocked
9. Stop only for login, 2FA, or the actual secret-value entry.

Safety rules:
- Do not paste the secret value into chat.
- Do not create any new Cloudflare products or paid upgrades.
- Do not change unrelated Worker settings.
```
