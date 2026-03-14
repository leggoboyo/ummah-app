export async function hasPackEntitlement({
  env,
  appUserId,
  requiredEntitlementKey,
}) {
  if (!requiredEntitlementKey) {
    return true;
  }
  const apiKey = env.REVENUECAT_API_KEY;
  if (!apiKey) {
    throw new Response(
      JSON.stringify({
        error: "Paid pack access is temporarily unavailable.",
      }),
      {
        status: 503,
        headers: { "content-type": "application/json" },
      },
    );
  }

  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "content-type": "application/json",
      },
    },
  );
  if (!response.ok) {
    throw new Error(`RevenueCat lookup failed (${response.status})`);
  }

  const payload = await response.json();
  const entitlements = payload?.subscriber?.entitlements || {};
  return Boolean(
    entitlements[requiredEntitlementKey]?.expires_date ||
      entitlements[requiredEntitlementKey]?.purchase_date ||
      entitlements.mega_bundle?.expires_date ||
      entitlements.mega_bundle?.purchase_date,
  );
}
