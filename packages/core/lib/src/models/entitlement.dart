enum AppEntitlement {
  coreFree,
  quranPlus,
  hadithPlus,
  aiQuran,
  aiHadith,
  scholarFeed,
  megaBundle,
}

extension AppEntitlementX on AppEntitlement {
  String get key {
    switch (this) {
      case AppEntitlement.coreFree:
        return 'core_free';
      case AppEntitlement.quranPlus:
        return 'quran_plus';
      case AppEntitlement.hadithPlus:
        return 'hadith_plus';
      case AppEntitlement.aiQuran:
        return 'ai_quran';
      case AppEntitlement.aiHadith:
        return 'ai_hadith';
      case AppEntitlement.scholarFeed:
        return 'scholar_feed';
      case AppEntitlement.megaBundle:
        return 'mega_bundle';
    }
  }

  String get title {
    switch (this) {
      case AppEntitlement.coreFree:
        return 'Core Free';
      case AppEntitlement.quranPlus:
        return 'Quran Plus';
      case AppEntitlement.hadithPlus:
        return 'Hadith Plus';
      case AppEntitlement.aiQuran:
        return 'Ask Quran AI';
      case AppEntitlement.aiHadith:
        return 'Ask Hadith AI';
      case AppEntitlement.scholarFeed:
        return 'Scholar Feed';
      case AppEntitlement.megaBundle:
        return 'Mega Bundle';
    }
  }
}

AppEntitlement? appEntitlementFromKey(String key) {
  for (final AppEntitlement entitlement in AppEntitlement.values) {
    if (entitlement.key == key) {
      return entitlement;
    }
  }
  return null;
}

bool hasEntitlement(
  Set<AppEntitlement> activeEntitlements,
  AppEntitlement requiredEntitlement,
) {
  return activeEntitlements.contains(AppEntitlement.megaBundle) ||
      activeEntitlements.contains(requiredEntitlement);
}
