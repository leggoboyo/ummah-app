#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_DIR="$ROOT_DIR/services/content-pack-worker"
PACKS_DIR="$ROOT_DIR/features/hadith/dist/packs"
OBJECTS_DIR="$PACKS_DIR/objects"
MANIFEST_PATH="$PACKS_DIR/manifest.json"
BUCKET_NAME="${1:-ummah-content-packs}"

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required to upload Hadith packs to Cloudflare R2." >&2
  exit 1
fi

if [[ ! -d "$OBJECTS_DIR" ]]; then
  echo "Pack objects directory not found: $OBJECTS_DIR" >&2
  exit 1
fi

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "Pack manifest not found: $MANIFEST_PATH" >&2
  exit 1
fi

cd "$WORKER_DIR"

echo "Checking Wrangler authentication..."
npx wrangler whoami >/dev/null

echo "Uploading Hadith pack objects to R2 bucket: $BUCKET_NAME"
while IFS= read -r -d '' object_path; do
  object_key="${object_path#"$OBJECTS_DIR"/}"
  echo "  -> $object_key"
  npx wrangler r2 object put "$BUCKET_NAME/$object_key" --file "$object_path" --remote
done < <(find "$OBJECTS_DIR" -type f -print0 | sort -z)

echo "Uploading staging and production manifests..."
npx wrangler r2 object put "$BUCKET_NAME/staging/manifest.json" --file "$MANIFEST_PATH" --remote
npx wrangler r2 object put "$BUCKET_NAME/prod/manifest.json" --file "$MANIFEST_PATH" --remote

echo "R2 upload complete."
