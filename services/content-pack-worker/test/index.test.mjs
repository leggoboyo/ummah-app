import test from "node:test";
import assert from "node:assert/strict";

import worker from "../src/index.mjs";
import { buildDownloadSignaturePayload, signPayload } from "../src/lib/signing.mjs";

const manifest = {
  generated_at: "2026-03-14T00:00:00Z",
  packs: [
    {
      pack_id: "hadith_pack_en",
      module: "hadithPack",
      object_key: "hadith/en/v1.24.0/pack.json.gz",
      file_hash: "abc123",
      pack_size_bytes: 3,
      version: "v1.24.0",
      is_starter_free_eligible: true,
      required_entitlement_key: "hadith_plus",
    },
  ],
};

function createEnv() {
  const objects = new Map([
    [
      "staging/manifest.json",
      {
        async text() {
          return JSON.stringify(manifest);
        },
      },
    ],
    [
      "hadith/en/v1.24.0/pack.json.gz",
      {
        body: new Uint8Array([1, 2, 3]),
        writeHttpMetadata(headers) {
          headers.set("content-length", "3");
        },
      },
    ],
  ]);

  return {
    PACKS_DEFAULT_ENVIRONMENT: "staging",
    PACK_DOWNLOAD_TTL_SECONDS: "180",
    DOWNLOAD_SIGNING_SECRET: "test-secret",
    REVENUECAT_API_KEY: "",
    STARTER_CLAIMS: {
      async get() {
        return JSON.stringify({
          packId: "hadith_pack_en",
          claimedAt: "2026-03-14T00:00:00Z",
        });
      },
      async put() {},
    },
    PACKS_BUCKET: {
      async get(key) {
        return objects.get(key) ?? null;
      },
    },
  };
}

test("access grants use a short-lived signed download URL", async () => {
  const env = createEnv();
  const response = await worker.fetch(
    new Request("https://worker.example/v1/packs/access", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        packId: "hadith_pack_en",
        appUserId: "ummah_0123456789abcdef0123456789abcdef",
        environment: "staging",
      }),
    }),
    env,
  );

  assert.equal(response.status, 200);
  const payload = await response.json();
  const ttlMs = Date.parse(payload.expiresAt) - Date.now();
  assert.ok(ttlMs <= 180_000);
  assert.ok(ttlMs > 60_000);
  assert.equal(payload.isFree, true);
});

test("download rejects object-key mismatches even with a valid-looking signature", async () => {
  const env = createEnv();
  const expiresAt = new Date(Date.now() + 90_000).toISOString();
  const signature = await signPayload(
    env.DOWNLOAD_SIGNING_SECRET,
    buildDownloadSignaturePayload({
      packId: "hadith_pack_en",
      objectKey: "hadith/ar/v1.7.0/pack.json.gz",
      appUserId: "ummah_0123456789abcdef0123456789abcdef",
      expiresAt,
    }),
  );

  const url = new URL("https://worker.example/v1/packs/download");
  url.searchParams.set("environment", "staging");
  url.searchParams.set("packId", "hadith_pack_en");
  url.searchParams.set("objectKey", "hadith/ar/v1.7.0/pack.json.gz");
  url.searchParams.set(
    "appUserId",
    "ummah_0123456789abcdef0123456789abcdef",
  );
  url.searchParams.set("expiresAt", expiresAt);
  url.searchParams.set("sig", signature);

  const response = await worker.fetch(new Request(url), env);

  assert.equal(response.status, 403);
});

test("download rejects expired signatures", async () => {
  const env = createEnv();
  const expiresAt = new Date(Date.now() - 10_000).toISOString();
  const signature = await signPayload(
    env.DOWNLOAD_SIGNING_SECRET,
    buildDownloadSignaturePayload({
      packId: "hadith_pack_en",
      objectKey: "hadith/en/v1.24.0/pack.json.gz",
      appUserId: "ummah_0123456789abcdef0123456789abcdef",
      expiresAt,
    }),
  );

  const url = new URL("https://worker.example/v1/packs/download");
  url.searchParams.set("environment", "staging");
  url.searchParams.set("packId", "hadith_pack_en");
  url.searchParams.set("objectKey", "hadith/en/v1.24.0/pack.json.gz");
  url.searchParams.set(
    "appUserId",
    "ummah_0123456789abcdef0123456789abcdef",
  );
  url.searchParams.set("expiresAt", expiresAt);
  url.searchParams.set("sig", signature);

  const response = await worker.fetch(new Request(url), env);

  assert.equal(response.status, 410);
});
