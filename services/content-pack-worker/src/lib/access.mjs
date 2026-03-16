import { hasPackEntitlement } from "./revenuecat.mjs";

const APP_USER_ID_PATTERN = /^ummah_[0-9a-f]{32}$/;
const DEFAULT_STARTER_CLAIMS_DAILY_BUDGET = 400;

export async function resolvePackAccess({
  env,
  pack,
  appUserId,
}) {
  if (!APP_USER_ID_PATTERN.test(appUserId)) {
    throw new Response(
      JSON.stringify({
        error: "The app user id format is invalid.",
      }),
      {
        status: 400,
        headers: { "content-type": "application/json" },
      },
    );
  }

  const claimKey = `starter:${appUserId}`;
  let isFree = false;

  if (pack.is_starter_free_eligible) {
    const existingClaim = await env.STARTER_CLAIMS.get(claimKey);
    if (!existingClaim) {
      await reserveStarterClaimBudget(env);
      await env.STARTER_CLAIMS.put(
        claimKey,
        JSON.stringify({
          packId: pack.pack_id,
          claimedAt: new Date().toISOString(),
        }),
      );
      isFree = true;
    } else if (parseClaimPackId(existingClaim) === pack.pack_id) {
      isFree = true;
    }
  }

  if (isFree) {
    return { isFree: true };
  }

  const hasEntitlement = await hasPackEntitlement({
    env,
    appUserId,
    requiredEntitlementKey: pack.required_entitlement_key,
  });
  if (!hasEntitlement) {
    throw new Response(
      JSON.stringify({
        error: "Pack access denied for this app user id.",
      }),
      {
        status: 403,
        headers: { "content-type": "application/json" },
      },
    );
  }
  return { isFree: false };
}

function parseClaimPackId(rawClaim) {
  try {
    const payload = JSON.parse(rawClaim);
    return `${payload.packId || ""}`.trim();
  } catch (_) {
    return `${rawClaim || ""}`.trim();
  }
}

async function reserveStarterClaimBudget(env) {
  const dailyBudget = resolveDailyBudget(env.STARTER_CLAIMS_DAILY_BUDGET);
  if (dailyBudget <= 0) {
    return;
  }

  const now = new Date();
  const budgetKey = `starter-budget:${now.toISOString().slice(0, 10)}`;
  const existing = await env.STARTER_CLAIMS.get(budgetKey);
  const currentCount = parseBudgetCount(existing);

  // KV makes this a best-effort daily cost guardrail, not a strict abuse-control counter.
  if (currentCount >= dailyBudget) {
    throw new Response(
      JSON.stringify({
        error: "Starter pack installs are temporarily paused for today.",
      }),
      {
        status: 503,
        headers: { "content-type": "application/json" },
      },
    );
  }

  await env.STARTER_CLAIMS.put(
    budgetKey,
    JSON.stringify({
      count: currentCount + 1,
      updatedAt: now.toISOString(),
    }),
    {
      expirationTtl: 60 * 60 * 24 * 2,
    },
  );
}

function resolveDailyBudget(rawBudget) {
  const parsed = Number.parseInt(`${rawBudget || DEFAULT_STARTER_CLAIMS_DAILY_BUDGET}`, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    return DEFAULT_STARTER_CLAIMS_DAILY_BUDGET;
  }
  return parsed;
}

function parseBudgetCount(rawValue) {
  if (!rawValue) {
    return 0;
  }
  try {
    const payload = JSON.parse(rawValue);
    const parsed = Number.parseInt(`${payload.count || 0}`, 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
  } catch (_) {
    const parsed = Number.parseInt(`${rawValue}`, 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
  }
}
