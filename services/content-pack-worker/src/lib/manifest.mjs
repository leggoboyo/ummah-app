function normalizeEnvironment(environment, fallback = "staging") {
  const normalized = `${environment || fallback}`.trim().toLowerCase();
  switch (normalized) {
    case "prod":
    case "production":
      return "prod";
    case "staging":
      return "staging";
    case "dev":
    default:
      return fallback === "prod" ? "prod" : "staging";
  }
}

function normalizeModule(module) {
  const normalized = `${module || ""}`.trim();
  if (!normalized) {
    return "";
  }
  if (normalized === "hadith_pack") {
    return "hadithPack";
  }
  return normalized;
}

export async function loadManifest(env, requestedEnvironment) {
  const environment = normalizeEnvironment(
    requestedEnvironment,
    env.PACKS_DEFAULT_ENVIRONMENT || "staging",
  );
  const objectKey = `${environment}/manifest.json`;
  const object = await env.PACKS_BUCKET.get(objectKey);
  if (!object) {
    throw new Response(
      JSON.stringify({
        error: `Pack manifest not found for environment "${environment}".`,
      }),
      {
        status: 404,
        headers: { "content-type": "application/json" },
      },
    );
  }

  const manifest = JSON.parse(await object.text());
  return { environment, manifest, objectKey };
}

export function filterManifest(manifest, requestedModule) {
  const module = normalizeModule(requestedModule);
  if (!module) {
    return manifest;
  }
  return {
    ...manifest,
    packs: (manifest.packs || []).filter((pack) => pack.module === module),
  };
}

export function findPack(manifest, packId) {
  return (manifest.packs || []).find((pack) => pack.pack_id === packId) || null;
}
