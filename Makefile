bootstrap:
	dart pub get
	dart run melos bootstrap

format-check:
	dart format --set-exit-if-changed .

analyze:
	dart run melos exec -c 1 -- flutter analyze

test:
	dart run melos exec -c 1 --dir-exists=test -- flutter test

worker-test:
	cd services/content-pack-worker && node --test

worker-upload-packs:
	./scripts/upload_hadith_packs_to_r2.sh

worker-deploy:
	cd services/content-pack-worker && npx wrangler deploy

cost-report:
	python3 scripts/estimate_cloudflare_costs.py

quality: bootstrap format-check analyze test worker-test

size-report:
	./scripts/report_build_sizes.sh
