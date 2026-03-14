import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:hadith/hadith.dart';

import '../content_packs/content_pack_registry.dart';

class HadithController extends ChangeNotifier {
  HadithController({
    HadithRepository? repository,
    ShiaHadithPackProvider? shiaProvider,
    required this.hasPremiumLanguageAccess,
    required this.appUserId,
    this.startupSelection,
    this.refreshPackAccess,
  })  : _repository = repository ?? HadithRepository(),
        _shiaProvider =
            shiaProvider ?? const PlaceholderShiaHadithPackProvider();

  final HadithRepository _repository;
  final ShiaHadithPackProvider _shiaProvider;

  final bool hasPremiumLanguageAccess;
  final String appUserId;
  final StartupSelection? startupSelection;
  final Future<void> Function()? refreshPackAccess;

  static const String _runtimeEnvironment =
      String.fromEnvironment('appFlavor', defaultValue: 'dev');

  bool isReady = false;
  bool isWorking = false;
  String? errorMessage;
  String? statusMessage;
  String? suggestedQuery;

  String _preferredLanguageCode = 'en';
  String _activeLanguageCode = 'en';
  String _searchQuery = '';

  List<HadithPackManifest> availablePacks = const <HadithPackManifest>[];
  List<HadithPackInstall> installedPacks = const <HadithPackInstall>[];
  List<HadithPackManifest> packUpdates = const <HadithPackManifest>[];
  List<HadithFinderResult> searchResults = const <HadithFinderResult>[];
  List<SourceVersion> sourceVersions = const <SourceVersion>[];
  ShiaHadithPackAvailability? shiaAvailability;

  String get preferredLanguageCode => _preferredLanguageCode;

  String get activeLanguageCode => _activeLanguageCode;

  String get searchQuery => _searchQuery;

  bool get hasInstalledPack => installedPacks.isNotEmpty;

  bool get shouldShowPackChooser => !hasInstalledPack;

  bool get isUsingFallbackLanguage => searchResults
      .any((HadithFinderResult result) => result.usedLanguageFallback);

  HadithPackManifest? get recommendedPack {
    final String canonicalPreferred =
        _canonicalizeLanguageCode(_preferredLanguageCode);
    for (final HadithPackManifest pack in availablePacks) {
      if (pack.languageCode == canonicalPreferred) {
        return pack;
      }
    }
    for (final HadithPackManifest pack in availablePacks) {
      if (pack.languageCode == 'en') {
        return pack;
      }
    }
    return availablePacks.isEmpty ? null : availablePacks.first;
  }

  HadithPackInstall? get activeInstalledPack {
    for (final HadithPackInstall install in installedPacks) {
      if (install.languageCode == _activeLanguageCode) {
        return install;
      }
    }
    return installedPacks.isEmpty ? null : installedPacks.first;
  }

  Future<void> initialize({
    required String preferredLanguageCode,
  }) async {
    if (isReady || isWorking) {
      return;
    }

    isWorking = true;
    notifyListeners();

    try {
      await _repository.initialize();
      _preferredLanguageCode = preferredLanguageCode;
      shiaAvailability = await _shiaProvider.getAvailability();
      await _reloadMetadata();
      _activeLanguageCode = _pickInitialLanguageCode();
      if (_shouldAutoInstallRecommendedPack()) {
        await installRecommendedPack();
      }
      isReady = true;
    } catch (error) {
      errorMessage = 'Hadith finder failed to initialize: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  bool _shouldAutoInstallRecommendedPack() {
    if (hasInstalledPack) {
      return false;
    }
    return startupSelection?.selectedPackIds
            .contains(AppContentPackIds.hadithPackDefault) ??
        false;
  }

  bool canInstallPack(HadithPackManifest pack) {
    final HadithPackManifest? recommended = recommendedPack;
    if (recommended == null) {
      return false;
    }
    return hasPremiumLanguageAccess ||
        pack.languageCode == recommended.languageCode;
  }

  bool isPackInstalled(String languageCode) {
    for (final HadithPackInstall install in installedPacks) {
      if (install.languageCode == languageCode) {
        return true;
      }
    }
    return false;
  }

  bool isPackUpdateAvailable(String languageCode) {
    for (final HadithPackManifest manifest in packUpdates) {
      if (manifest.languageCode == languageCode) {
        return true;
      }
    }
    return false;
  }

  Future<void> installRecommendedPack() async {
    final HadithPackManifest? pack = recommendedPack;
    if (pack == null) {
      errorMessage = 'No remote Sunni Hadith pack is available right now.';
      notifyListeners();
      return;
    }
    await installPack(pack.languageCode);
  }

  Future<void> installPack(String languageCode) async {
    final HadithPackManifest? pack = await _repository.getPackForLanguage(
      languageCode,
    );
    if (pack == null) {
      errorMessage =
          'No remote Sunni Hadith pack is available for $languageCode.';
      notifyListeners();
      return;
    }
    if (!canInstallPack(pack)) {
      errorMessage =
          'That language pack is part of Hadith Plus. The recommended pack stays free.';
      notifyListeners();
      return;
    }
    if (appUserId.trim().isEmpty) {
      errorMessage = 'This device is missing its Hadith pack identity.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      errorMessage = null;
      HadithPackInstall install;
      try {
        install = await _repository.installRemotePack(
          languageCode: languageCode,
          appUserId: appUserId,
          platform: _currentPlatform,
          environment: _runtimeEnvironment,
        );
      } on HadithPackAccessDeniedException {
        if (hasPremiumLanguageAccess && refreshPackAccess != null) {
          await refreshPackAccess!();
          install = await _repository.installRemotePack(
            languageCode: languageCode,
            appUserId: appUserId,
            platform: _currentPlatform,
            environment: _runtimeEnvironment,
          );
        } else {
          rethrow;
        }
      }
      await _reloadMetadata();
      _activeLanguageCode = install.languageCode;
      statusMessage =
          'Installed ${install.languageName} Sunni Hadith pack for offline use.';
      if (_searchQuery.trim().isNotEmpty) {
        await _refreshSearch();
      }
    });
  }

  Future<void> removePack(String languageCode) async {
    await _runBusy(() async {
      await _repository.removePack(languageCode: languageCode);
      await _reloadMetadata();
      _activeLanguageCode = _pickInitialLanguageCode();
      if (_searchQuery.trim().isNotEmpty) {
        await _refreshSearch();
      }
      statusMessage = 'Removed the ${languageCode.toUpperCase()} Hadith pack.';
    });
  }

  Future<void> setActiveLanguageCode(String languageCode) async {
    _activeLanguageCode = _canonicalizeLanguageCode(languageCode);
    statusMessage = null;
    errorMessage = null;
    if (_searchQuery.trim().isNotEmpty) {
      await _refreshSearch();
    }
    notifyListeners();
  }

  Future<void> updateSearchQuery(String value) async {
    _searchQuery = value;
    errorMessage = null;
    statusMessage = null;
    await _refreshSearch();
    notifyListeners();
  }

  Future<void> applySuggestedQuery() async {
    final String? nextQuery = suggestedQuery;
    if (nextQuery == null || nextQuery.isEmpty) {
      return;
    }
    _searchQuery = nextQuery;
    suggestedQuery = null;
    await _refreshSearch();
    notifyListeners();
  }

  Future<HadithDetail?> loadHadithDetail({
    required String languageCode,
    required int hadithId,
  }) {
    return _repository.getHadithDetail(
      languageCode: languageCode,
      hadithId: hadithId,
    );
  }

  Future<void> _refreshSearch() async {
    final String trimmed = _searchQuery.trim();
    if (trimmed.length < 2) {
      searchResults = const <HadithFinderResult>[];
      suggestedQuery = null;
      return;
    }
    if (!hasInstalledPack) {
      searchResults = const <HadithFinderResult>[];
      suggestedQuery = null;
      return;
    }

    searchResults = await _repository.findForUseCase(
      query: trimmed,
      preferredLanguageCode: _activeLanguageCode,
      limit: 24,
    );
    if (searchResults.isEmpty) {
      suggestedQuery = await _repository.suggestQuery(
        query: trimmed,
        preferredLanguageCode: _activeLanguageCode,
      );
    } else {
      suggestedQuery = null;
    }
  }

  Future<void> _reloadMetadata() async {
    installedPacks = await _repository.getInstalledPacks();
    sourceVersions = await _repository.getSourceVersions();
    try {
      availablePacks = await _repository.getAvailablePacks();
      packUpdates = await _repository.getAvailablePackUpdates();
    } catch (error) {
      availablePacks = const <HadithPackManifest>[];
      packUpdates = const <HadithPackManifest>[];
      if (installedPacks.isEmpty) {
        errorMessage ??=
            'Remote Hadith packs are unavailable right now: $error';
      }
    }
  }

  Future<void> _runBusy(Future<void> Function() operation) async {
    isWorking = true;
    notifyListeners();

    try {
      await operation();
    } catch (error) {
      errorMessage = '$error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  String _pickInitialLanguageCode() {
    final String preferred = _canonicalizeLanguageCode(_preferredLanguageCode);
    for (final HadithPackInstall install in installedPacks) {
      if (install.languageCode == preferred) {
        return preferred;
      }
    }
    final HadithPackManifest? recommended = recommendedPack;
    if (recommended != null && isPackInstalled(recommended.languageCode)) {
      return recommended.languageCode;
    }
    return installedPacks.isEmpty
        ? preferred
        : installedPacks.first.languageCode;
  }

  String _canonicalizeLanguageCode(String raw) {
    final String normalized = raw.trim().toLowerCase();
    if (normalized.contains('_')) {
      return normalized.split('_').first;
    }
    if (normalized.contains('-')) {
      return normalized.split('-').first;
    }
    return normalized;
  }

  String get _currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
      default:
        return 'android';
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
