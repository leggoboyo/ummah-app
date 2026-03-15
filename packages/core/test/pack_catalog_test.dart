import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('pack catalog parses deterministic generated label and sources', () {
    final PackCatalog catalog = PackCatalog.fromJson(
      <String, Object?>{
        'generated_label': 'Bundled with this build from canonical manifests.',
        'packs': <Object?>[
          <String, Object?>{
            'pack_id': 'quran_arabic',
            'module_id': 'quran_reader',
            'title': 'Quran Arabic Text',
            'summary': 'Bundled Tanzil Arabic corpus.',
            'version': '1.1.0',
            'locales': <String>['ar'],
            'size_bytes': 1396087,
            'sha256':
                '6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f',
            'content_type': 'text',
            'delivery_type': 'bundled',
            'install_steps': <String>[
              'seed bundled corpus into the local Quran database on first launch',
            ],
            'compatibility': <String>['offline', 'canonical_text'],
            'sources': <Object?>[
              <String, Object?>{
                'name': 'Tanzil Project',
                'url': 'https://tanzil.net/download/',
                'version': '1.1',
                'license_summary': 'Verbatim redistribution only.',
                'attribution_required': true,
                'no_modify_required': true,
                'verbatim_only': true,
              },
            ],
          },
        ],
      },
    );

    expect(
      catalog.generatedLabel,
      'Bundled with this build from canonical manifests.',
    );
    expect(catalog.packs, hasLength(1));
    expect(catalog.packs.single.packId, 'quran_arabic');
    expect(catalog.packs.single.contentType, PackContentType.text);
    expect(catalog.packs.single.deliveryType, PackDeliveryType.bundled);
    expect(catalog.packs.single.sources.single.verbatimOnly, isTrue);
  });
}
