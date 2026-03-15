import 'dart:convert';

import 'package:core/core.dart';
import 'package:fiqh/fiqh.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hadith/hadith.dart';
import 'package:quran/quran.dart';
import 'package:scholar_feed/scholar_feed.dart';

import '../bootstrap/shared_preferences_key_value_store.dart';
import '../content_packs/content_pack_registry.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    QuranRepository? quranRepository,
    HadithRepository? hadithRepository,
    FiqhRepository? fiqhRepository,
    ScholarFeedRepository? scholarFeedRepository,
    ContentPackRegistry? contentPackRegistry,
    AppModuleRegistry? moduleRegistry,
    Set<AppEntitlement> activeEntitlements = const <AppEntitlement>{
      AppEntitlement.coreFree,
    },
    this.preferredLanguageCode = 'en',
  })  : _quranRepository = quranRepository ?? QuranRepository(),
        _hadithRepository = hadithRepository ?? HadithRepository(),
        _fiqhRepository = fiqhRepository ?? FiqhRepository(),
        _scholarFeedRepository = scholarFeedRepository ??
            ScholarFeedRepository(
              keyValueStore: SharedPreferencesKeyValueStore(),
            ),
        _contentPackRegistry = contentPackRegistry ?? ContentPackRegistry(),
        _moduleRegistry = moduleRegistry ?? buildDefaultAppModuleRegistry(),
        _activeEntitlements = activeEntitlements;

  final QuranRepository _quranRepository;
  final HadithRepository _hadithRepository;
  final FiqhRepository _fiqhRepository;
  final ScholarFeedRepository _scholarFeedRepository;
  final ContentPackRegistry _contentPackRegistry;
  final AppModuleRegistry _moduleRegistry;
  final Set<AppEntitlement> _activeEntitlements;
  final String preferredLanguageCode;

  static const String _sourceCatalogAsset =
      'assets/generated/source_catalog.json';

  bool isReady = false;
  bool isWorking = false;
  String? errorMessage;

  List<SourceVersion> quranSourceVersions = const <SourceVersion>[];
  List<SourceVersion> hadithSourceVersions = const <SourceVersion>[];
  List<SourceVersion> fiqhSourceVersions = const <SourceVersion>[];
  List<InstalledContentPack> installedContentPacks =
      const <InstalledContentPack>[];
  List<ResolvedAppModule> moduleDirectory = const <ResolvedAppModule>[];
  PackCatalog? packCatalog;
  List<ScholarFeedSource> scholarFeedSources = const <ScholarFeedSource>[];
  Set<String> followedScholarFeedSources = <String>{};
  DateTime? scholarFeedLastSyncedAt;
  int scholarFeedCachedItemCount = 0;

  Future<void> initialize() async {
    if (isReady || isWorking) {
      return;
    }
    await refresh();
    isReady = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    isWorking = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _quranRepository.initialize();
      await _hadithRepository.initialize();
      await _fiqhRepository.initialize();
      await _contentPackRegistry.initialize();

      quranSourceVersions = await _quranRepository.getSourceVersions();
      hadithSourceVersions = await _hadithRepository.getSourceVersions();
      fiqhSourceVersions = await _fiqhRepository.getSourceVersions();
      installedContentPacks = await _contentPackRegistry.getInstalledPacks(
        preferredLanguageCode: preferredLanguageCode,
      );
      moduleDirectory = _moduleRegistry.resolve(
        installedPackIds: installedContentPacks
            .map((InstalledContentPack pack) => pack.packId)
            .toSet(),
        activeEntitlements: _activeEntitlements,
      );
      packCatalog = await _loadPackCatalog();

      scholarFeedSources = await _scholarFeedRepository.getAvailableSources();
      final ScholarFeedSyncResult cached =
          await _scholarFeedRepository.getCachedFeed();
      followedScholarFeedSources = cached.followedSourceIds;
      scholarFeedLastSyncedAt = cached.lastSyncedAt;
      scholarFeedCachedItemCount = cached.items.length;
    } catch (error) {
      errorMessage = 'Settings metadata failed to load: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<PackCatalog?> _loadPackCatalog() async {
    try {
      final String raw = await rootBundle.loadString(_sourceCatalogAsset);
      return PackCatalog.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  List<ScholarFeedSource> get followedScholarSources {
    return scholarFeedSources
        .where((ScholarFeedSource source) =>
            followedScholarFeedSources.contains(source.id))
        .toList(growable: false);
  }

  Future<void> close() async {
    await _quranRepository.dispose();
    await _hadithRepository.dispose();
    await _scholarFeedRepository.dispose();
    await _contentPackRegistry.dispose();
  }
}
