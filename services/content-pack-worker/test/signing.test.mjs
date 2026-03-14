import test from "node:test";
import assert from "node:assert/strict";

import {
  buildDownloadSignaturePayload,
  signPayload,
  verifyPayload,
} from "../src/lib/signing.mjs";

test("signPayload and verifyPayload round-trip", async () => {
  const secret = "test-secret";
  const payload = buildDownloadSignaturePayload({
    packId: "hadith_pack:en",
    objectKey: "hadith/en/v1.24.0/pack.json.gz",
    appUserId: "ummah_0123456789abcdef0123456789abcdef",
    expiresAt: "2026-03-13T00:00:00Z",
  });
  const signature = await signPayload(secret, payload);

  assert.equal(await verifyPayload({ secret, payload, signature }), true);
  assert.equal(
    await verifyPayload({
      secret,
      payload: buildDownloadSignaturePayload({
        packId: "hadith_pack:en",
        objectKey: "hadith/en/v1.24.0/pack.json.gz",
        appUserId: "ummah_deadbeefdeadbeefdeadbeefdeadbe",
        expiresAt: "2026-03-13T00:00:00Z",
      }),
      signature,
    }),
    false,
  );
});
