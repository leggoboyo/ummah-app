import test from "node:test";
import assert from "node:assert/strict";

import { resolvePackAccess } from "../src/lib/access.mjs";

function buildEnv({ claimValue = null, revenueCatApiKey = "rc_secret" } = {}) {
  const values = new Map();
  if (claimValue !== null) {
    values.set("starter:ummah_0123456789abcdef0123456789abcdef", claimValue);
  }
  return {
    STARTER_CLAIMS_DAILY_BUDGET: "400",
    STARTER_CLAIMS: {
      async get(key) {
        return values.get(key) ?? null;
      },
      async put(key, value) {
        values.set(key, value);
      },
    },
    REVENUECAT_API_KEY: revenueCatApiKey,
  };
}

test("starter-free packs claim once and remain idempotent", async () => {
  const pack = {
    pack_id: "hadith_pack_en",
    is_starter_free_eligible: true,
    required_entitlement_key: "hadith_plus",
  };

  const env = {
    STARTER_CLAIMS: {
      async get() {
        return JSON.stringify({
          packId: "hadith_pack_en",
          claimedAt: "2026-03-14T00:00:00Z",
        });
      },
      async put() {},
    },
  };

  const access = await resolvePackAccess({
    env,
    pack,
    appUserId: "ummah_0123456789abcdef0123456789abcdef",
  });

  assert.deepEqual(access, { isFree: true });
});

test("invalid app user ids are rejected before access checks", async () => {
  const pack = {
    pack_id: "hadith_pack_en",
    is_starter_free_eligible: true,
    required_entitlement_key: null,
  };

  await assert.rejects(
    () =>
      resolvePackAccess({
        env: buildEnv(),
        pack,
        appUserId: "guessable-id",
      }),
    (error) => error instanceof Response && error.status === 400,
  );
});

test("starter-free packs stop once the daily budget is exhausted", async () => {
  const pack = {
    pack_id: "hadith_pack_en",
    is_starter_free_eligible: true,
    required_entitlement_key: "hadith_plus",
  };

  const env = {
    STARTER_CLAIMS_DAILY_BUDGET: "1",
    STARTER_CLAIMS: {
      async get(key) {
        if (key.startsWith("starter-budget:")) {
          return JSON.stringify({
            count: 1,
            updatedAt: "2026-03-14T00:00:00Z",
          });
        }
        return null;
      },
      async put() {},
    },
  };

  await assert.rejects(
    () =>
      resolvePackAccess({
        env,
        pack,
        appUserId: "ummah_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      }),
    (error) =>
      error instanceof Response &&
      error.status === 503,
  );
});

test("paid packs fail closed when the RevenueCat secret is missing", async () => {
  const pack = {
    pack_id: "hadith_pack_ar",
    is_starter_free_eligible: false,
    required_entitlement_key: "hadith_plus",
  };

  await assert.rejects(
    () =>
      resolvePackAccess({
        env: buildEnv({ revenueCatApiKey: "" }),
        pack,
        appUserId: "ummah_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      }),
    (error) =>
      error instanceof Response &&
      error.status === 503,
  );
});

test("paid packs are allowed only when RevenueCat confirms the entitlement", async () => {
  const pack = {
    pack_id: "hadith_pack_ar",
    is_starter_free_eligible: false,
    required_entitlement_key: "hadith_plus",
  };
  const originalFetch = global.fetch;
  global.fetch = async () =>
    new Response(
      JSON.stringify({
        subscriber: {
          entitlements: {
            hadith_plus: {
              purchase_date: "2026-03-14T00:00:00Z",
            },
          },
        },
      }),
      {
        status: 200,
        headers: { "content-type": "application/json" },
      },
    );

  try {
    const access = await resolvePackAccess({
      env: buildEnv(),
      pack,
      appUserId: "ummah_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    });

    assert.deepEqual(access, { isFree: false });
  } finally {
    global.fetch = originalFetch;
  }
});
