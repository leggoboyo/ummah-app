import { resolvePackAccess } from "./lib/access.mjs";
import { filterManifest, findPack, loadManifest } from "./lib/manifest.mjs";
import {
  buildDownloadSignaturePayload,
  signPayload,
  verifyPayload,
} from "./lib/signing.mjs";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    try {
      if (request.method === "GET" && url.pathname === "/v1/packs/manifest") {
        return await handleManifest(request, env);
      }
      if (request.method === "POST" && url.pathname === "/v1/packs/access") {
        return await handleAccess(request, env);
      }
      if (request.method === "GET" && url.pathname === "/v1/packs/download") {
        return await handleDownload(request, env);
      }
      return json(
        {
          error: "Not found",
        },
        404,
      );
    } catch (error) {
      if (error instanceof Response) {
        return error;
      }
      return json(
        {
          error: `${error}`,
        },
        500,
      );
    }
  },
};

async function handleManifest(request, env) {
  const url = new URL(request.url);
  const { environment, manifest } = await loadManifest(
    env,
    url.searchParams.get("environment"),
  );
  const filtered = filterManifest(manifest, url.searchParams.get("module"));
  return json({
    environment,
    generated_at: filtered.generated_at,
    packs: (filtered.packs || []).map((pack) => ({
      ...pack,
      manifest_url: new URL(
        `/v1/packs/manifest?environment=${encodeURIComponent(environment)}`,
        request.url,
      ).toString(),
    })),
  });
}

async function handleAccess(request, env) {
  const body = await request.json();
  const packId = `${body.packId || ""}`.trim();
  const appUserId = `${body.appUserId || ""}`.trim();
  if (!packId || !appUserId) {
    return json(
      {
        error: "packId and appUserId are required.",
      },
      400,
    );
  }

  const { environment, manifest } = await loadManifest(env, body.environment);
  const pack = findPack(manifest, packId);
  if (!pack) {
    return json(
      {
        error: `Unknown pack "${packId}".`,
      },
      404,
    );
  }

  const access = await resolvePackAccess({
    env,
    pack,
    appUserId,
  });

  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
  const signaturePayload = buildDownloadSignaturePayload({
    packId: pack.pack_id,
    objectKey: pack.object_key,
    appUserId,
    expiresAt,
  });
  const signature = await signPayload(env.DOWNLOAD_SIGNING_SECRET, signaturePayload);
  const downloadUrl = new URL("/v1/packs/download", request.url);
  downloadUrl.searchParams.set("packId", pack.pack_id);
  downloadUrl.searchParams.set("objectKey", pack.object_key);
  downloadUrl.searchParams.set("appUserId", appUserId);
  downloadUrl.searchParams.set("expiresAt", expiresAt);
  downloadUrl.searchParams.set("sig", signature);
  downloadUrl.searchParams.set("environment", environment);

  return json({
    packId: pack.pack_id,
    downloadUrl: downloadUrl.toString(),
    expiresAt,
    sha256: pack.file_hash,
    sizeBytes: pack.pack_size_bytes,
    version: pack.version,
    isFree: access.isFree,
  }, 200, {
    "cache-control": "no-store",
  });
}

async function handleDownload(request, env) {
  const url = new URL(request.url);
  const packId = url.searchParams.get("packId") || "";
  const objectKey = url.searchParams.get("objectKey") || "";
  const appUserId = url.searchParams.get("appUserId") || "";
  const expiresAt = url.searchParams.get("expiresAt") || "";
  const signature = url.searchParams.get("sig") || "";
  if (!packId || !objectKey || !appUserId || !expiresAt || !signature) {
    return json(
      {
        error: "Missing required signed download fields.",
      },
      400,
    );
  }
  if (Date.parse(expiresAt) <= Date.now()) {
    return json(
      {
        error: "Download URL has expired.",
      },
      410,
    );
  }

  const { environment, manifest } = await loadManifest(
    env,
    url.searchParams.get("environment"),
  );
  const pack = findPack(manifest, packId);
  if (!pack || pack.object_key !== objectKey) {
    return json(
      {
        error: "Pack download request is invalid for the selected environment.",
      },
      403,
    );
  }

  const signaturePayload = buildDownloadSignaturePayload({
    packId,
    objectKey,
    appUserId,
    expiresAt,
  });
  const isValid = await verifyPayload({
    secret: env.DOWNLOAD_SIGNING_SECRET,
    payload: signaturePayload,
    signature,
  });
  if (!isValid) {
    return json(
      {
        error: "Download signature is invalid.",
      },
      403,
    );
  }

  const object = await env.PACKS_BUCKET.get(objectKey);
  if (!object) {
    return json(
      {
        error: `Pack object "${objectKey}" was not found.`,
      },
      404,
    );
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("content-type", "application/gzip");
  headers.set("cache-control", "no-store");
  headers.set("content-disposition", `attachment; filename="${pack.pack_id}.json.gz"`);
  headers.set("x-content-type-options", "nosniff");
  headers.set("x-ummah-pack-environment", environment);
  return new Response(object.body, {
    status: 200,
    headers,
  });
}

function json(payload, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "content-type": "application/json",
      ...extraHeaders,
    },
  });
}
