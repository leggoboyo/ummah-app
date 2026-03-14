import 'package:core/core.dart';

import '../domain/subscription_product.dart';

List<SubscriptionProduct> buildDefaultSubscriptionCatalog() {
  return const <SubscriptionProduct>[
    SubscriptionProduct(
      id: 'mega_bundle_monthly:monthly',
      title: 'Mega Bundle',
      tagline: 'Best value when you want every paid module.',
      description:
          'Includes Quran Plus, Hadith Plus, Ask Quran AI, Ask Hadith AI, and Scholar Feed.',
      kind: SubscriptionProductKind.subscription,
      primaryEntitlement: AppEntitlement.megaBundle,
      includesEntitlements: <AppEntitlement>{
        AppEntitlement.megaBundle,
        AppEntitlement.quranPlus,
        AppEntitlement.hadithPlus,
        AppEntitlement.aiQuran,
        AppEntitlement.aiHadith,
        AppEntitlement.scholarFeed,
      },
      isFeatured: true,
    ),
    SubscriptionProduct(
      id: 'quran_plus_addon',
      title: 'Quran Plus',
      tagline: 'Audio packs, tafsir upgrades, and premium Quran study tools.',
      description:
          'Unlocks optional Quran audio packs, future tafsir/study upgrades, and keeps the base reader free.',
      kind: SubscriptionProductKind.lifetimeAddOn,
      primaryEntitlement: AppEntitlement.quranPlus,
      includesEntitlements: <AppEntitlement>{
        AppEntitlement.quranPlus,
      },
      isFeatured: false,
    ),
    SubscriptionProduct(
      id: 'hadith_plus_addon',
      title: 'Hadith Plus',
      tagline:
          'Extra Hadith language packs, advanced study tools, and future licensed expansions.',
      description:
          'Keeps the core Sunni Hadith Finder free while unlocking extra language packs and future premium Hadith study features.',
      kind: SubscriptionProductKind.lifetimeAddOn,
      primaryEntitlement: AppEntitlement.hadithPlus,
      includesEntitlements: <AppEntitlement>{
        AppEntitlement.hadithPlus,
      },
      isFeatured: true,
    ),
    SubscriptionProduct(
      id: 'ai_quran_monthly:monthly',
      title: 'Ask Quran AI',
      tagline: 'Citation-first Quran Q&A with BYOK or hosted AI later.',
      description:
          'Unlocks the Quran retrieval assistant with BYOK support and citation-first answers.',
      kind: SubscriptionProductKind.subscription,
      primaryEntitlement: AppEntitlement.aiQuran,
      includesEntitlements: <AppEntitlement>{
        AppEntitlement.aiQuran,
      },
      isFeatured: false,
    ),
    SubscriptionProduct(
      id: 'ai_hadith_monthly:monthly',
      title: 'Ask Hadith AI',
      tagline: 'Citation-first hadith Q&A with explicit safety boundaries.',
      description:
          'Unlocks the hadith retrieval assistant and includes Hadith Plus for extra bundled Hadith languages and future premium study tools.',
      kind: SubscriptionProductKind.subscription,
      primaryEntitlement: AppEntitlement.aiHadith,
      includesEntitlements: <AppEntitlement>{
        AppEntitlement.aiHadith,
        AppEntitlement.hadithPlus,
      },
      isFeatured: false,
    ),
    SubscriptionProduct(
      id: 'scholar_feed_monthly:monthly',
      title: 'Scholar Feed',
      tagline: 'Follow trusted article and fatwa sources by language.',
      description:
          'Unlocks the curated source feed with local caching and source-directory controls.',
      kind: SubscriptionProductKind.subscription,
      primaryEntitlement: AppEntitlement.scholarFeed,
      includesEntitlements: <AppEntitlement>{
        AppEntitlement.scholarFeed,
      },
      isFeatured: false,
    ),
  ];
}
