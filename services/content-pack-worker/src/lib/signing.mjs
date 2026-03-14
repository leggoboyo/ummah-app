const encoder = new TextEncoder();

function toHex(bytes) {
  return [...bytes].map((value) => value.toString(16).padStart(2, "0")).join("");
}

export async function signPayload(secret, payload) {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
  return toHex(new Uint8Array(signature));
}

export function buildDownloadSignaturePayload({
  packId,
  objectKey,
  appUserId,
  expiresAt,
}) {
  return `${packId}:${objectKey}:${appUserId}:${expiresAt}`;
}

export async function verifyPayload({ secret, payload, signature }) {
  const expected = await signPayload(secret, payload);
  return timingSafeEqual(expected, signature);
}

function timingSafeEqual(left, right) {
  if (left.length != right.length) {
    return false;
  }
  let mismatch = 0;
  for (let index = 0; index < left.length; index += 1) {
    mismatch |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return mismatch === 0;
}
