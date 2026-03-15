bootstrap:
	dart pub get
	dart run melos bootstrap

repo-reality-report:
	python3 scripts/generate_repo_reality_report.py

workflow-lint:
	@if command -v actionlint >/dev/null 2>&1; then \
		actionlint -color; \
	else \
		echo "actionlint is required for workflow linting. Install it first (for example: brew install actionlint)." >&2; \
		exit 1; \
	fi

feature-boundary-check:
	python3 scripts/check_feature_boundaries.py

secret-file-check:
	python3 scripts/check_tracked_secret_files.py

validate-packs:
	python3 scripts/validate_packs.py

generate-sources:
	python3 scripts/generate_sources_site.py

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

android-smoke:
	./scripts/android_smoke_test.sh

android-low-end-avd:
	./scripts/create_low_end_android_avd.sh

build-android-debug:
	cd mobile/app && flutter build apk --debug

build-android-release:
	cd mobile/app && flutter build apk --release

build-android-split:
	cd mobile/app && flutter build apk --release --split-per-abi

build-android-aab:
	cd mobile/app && flutter build appbundle --release

site-preview:
	python3 -m http.server 4173 --directory website

quality: bootstrap format-check pack-platform-check analyze test worker-test

pack-platform-check: feature-boundary-check secret-file-check validate-packs generate-sources

size-report:
	./scripts/report_build_sizes.sh
