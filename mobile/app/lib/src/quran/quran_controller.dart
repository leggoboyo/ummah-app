import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart';

import '../bootstrap/app_profile.dart';

class QuranController extends ChangeNotifier {
  QuranController({
    QuranRepository? repository,
    this.startupMode = QuranStartupMode.fullTranslation,
    this.startupSelection,
  }) : _repository = repository ?? QuranRepository();

  final QuranRepository _repository;
  final QuranStartupMode startupMode;
  final StartupSelection? startupSelection;

  bool isReady = false;
  bool isWorking = false;
  String? statusMessage;
  String? errorMessage;
  String? searchAssistMessage;
  String? suggestedQuery;
  bool _startupSyncInProgress = false;
  bool _cancelStartupDownloadRequested = false;

  String _preferredLanguageCode = 'en';
  String _catalogLanguageCode = 'en';
  String _searchQuery = '';
  int _selectedSurahNumber = 1;
  String? _selectedTranslationKey;

  List<SurahSummary> surahs = const <SurahSummary>[];
  List<QuranAyah> currentAyahs = const <QuranAyah>[];
  List<QuranSearchResult> searchResults = const <QuranSearchResult>[];
  List<QuranTranslationInfo> availableTranslations =
      const <QuranTranslationInfo>[];
  List<SourceVersion> sourceVersions = const <SourceVersion>[];

  String get searchQuery => _searchQuery;

  int get selectedSurahNumber => _selectedSurahNumber;

  String get catalogLanguageCode => _catalogLanguageCode;

  String? get selectedTranslationKey => _selectedTranslationKey;

  SurahSummary? get selectedSurah {
    for (final SurahSummary surah in surahs) {
      if (surah.number == _selectedSurahNumber) {
        return surah;
      }
    }
    return null;
  }

  QuranTranslationInfo? get selectedTranslation {
    final String? key = _selectedTranslationKey;
    if (key == null) {
      return null;
    }

    for (final QuranTranslationInfo translation in availableTranslations) {
      if (translation.key == key) {
        return translation;
      }
    }
    return null;
  }

  String? get downloadedTranslationKey {
    final QuranTranslationInfo? translation = selectedTranslation;
    if (translation == null || !translation.isDownloaded) {
      return null;
    }
    return translation.key;
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
      _preferredLanguageCode = preferredLanguageCode;
      _catalogLanguageCode = _normalizeCatalogLanguage(preferredLanguageCode);
      await _repository.initialize();
      surahs = await _repository.getSurahs();
      if (surahs.isNotEmpty) {
        _selectedSurahNumber = surahs.first.number;
      }
      await _refreshLocalState();
      await _loadCurrentSurah();
      isReady = true;
    } catch (error) {
      errorMessage = 'Quran module failed to initialize: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> refreshTranslationCatalog() async {
    await _runBusy(() async {
      await _refreshTranslationCatalogInternal(
        suppressNetworkErrors: false,
      );
    });
  }

  Future<void> prepareInitialExperience() async {
    if (!isReady || _startupSyncInProgress) {
      return;
    }

    _startupSyncInProgress = true;
    notifyListeners();

    try {
      if (availableTranslations.isEmpty) {
        await _refreshTranslationCatalogInternal(
          suppressNetworkErrors: true,
        );
      }

      final bool shouldAutoDownloadPreferredTranslation = startupSelection
              ?.selectedPackIds
              .contains(AppContentPackIds.quranTranslationDefault) ??
          startupMode != QuranStartupMode.arabicOnly;

      if (_preferredLanguageCode == 'ar' ||
          !shouldAutoDownloadPreferredTranslation) {
        statusMessage ??= 'Arabic text is ready offline on this device.';
        return;
      }

      final QuranTranslationInfo? translation = selectedTranslation;
      if (translation == null) {
        statusMessage ??=
            'Arabic is ready offline. The phone-language translation will download automatically the next time you open Quran while online.';
        return;
      }

      if (translation.isFullyDownloaded) {
        statusMessage ??=
            '${translation.title} is already downloaded on this device.';
        return;
      }

      _cancelStartupDownloadRequested = false;
      final QuranSyncOutcome outcome = await _downloadFullTranslationInternal(
        translationKey: translation.key,
        translationTitle: translation.title,
        suppressNetworkErrors: true,
        userVisibleProgress: false,
        allowCancellation: true,
      );

      if (!outcome.completed) {
        statusMessage =
            'Arabic is ready offline. ${translation.title} will keep downloading automatically when Quran is idle.';
      }
    } finally {
      _startupSyncInProgress = false;
      notifyListeners();
    }
  }

  void pauseBackgroundPreparation() {
    _cancelStartupDownloadRequested = true;
  }

  Future<void> selectTranslation(String? translationKey) async {
    _selectedTranslationKey =
        translationKey?.isEmpty == true ? null : translationKey;
    errorMessage = null;
    statusMessage = null;
    await _reloadVisibleContent();
    notifyListeners();
  }

  Future<void> selectSurah(int surahNumber) async {
    _selectedSurahNumber = surahNumber;
    if (_searchQuery.trim().isEmpty) {
      await _loadCurrentSurah();
    }
    notifyListeners();
  }

  Future<void> updateSearchQuery(String value) async {
    _searchQuery = value;
    errorMessage = null;
    searchAssistMessage = null;
    suggestedQuery = null;
    await _reloadVisibleContent();
    notifyListeners();
  }

  Future<void> downloadCurrentSurahTranslation() async {
    _cancelStartupDownloadRequested = true;
    final String? translationKey = _selectedTranslationKey;
    if (translationKey == null) {
      errorMessage =
          'Choose a translation first, then download the current surah.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final int syncedCount = await _repository.syncTranslationSurahs(
        translationKey: translationKey,
        surahNumbers: <int>[_selectedSurahNumber],
      );
      await _refreshLocalState();
      await _reloadVisibleContent();
      statusMessage =
          'Downloaded $syncedCount verses for Surah ${selectedSurah?.transliteration ?? _selectedSurahNumber}.';
    });
  }

  Future<void> downloadPopularSurahs() async {
    await downloadFullTranslation();
  }

  Future<void> downloadFullTranslation() async {
    _cancelStartupDownloadRequested = true;
    final String? translationKey = _selectedTranslationKey;
    if (translationKey == null) {
      errorMessage =
          'Choose a translation first, then download the full translation.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      await _downloadFullTranslationInternal(
        translationKey: translationKey,
        translationTitle: selectedTranslation?.title ?? 'translation',
        suppressNetworkErrors: false,
        userVisibleProgress: true,
        allowCancellation: false,
      );
    });
  }

  Future<void> removeSelectedTranslation() async {
    final String? translationKey = _selectedTranslationKey;
    if (translationKey == null || translationKey.isEmpty) {
      errorMessage = 'Select a translation first, then remove it.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final String title = selectedTranslation?.title ?? 'translation';
      await _repository.removeTranslation(translationKey: translationKey);
      await _refreshLocalState();
      await _reloadVisibleContent();
      statusMessage = 'Removed $title from offline storage.';
    });
  }

  Future<void> _reloadVisibleContent() async {
    if (_searchQuery.trim().isEmpty) {
      searchResults = const <QuranSearchResult>[];
      searchAssistMessage = null;
      suggestedQuery = null;
      await _loadCurrentSurah();
      return;
    }

    currentAyahs = const <QuranAyah>[];
    searchResults = await _repository.search(
      _searchQuery,
      translationKey: downloadedTranslationKey,
    );

    if (searchResults.isEmpty) {
      suggestedQuery = await _repository.suggestQuery(
        _searchQuery,
        translationKey: downloadedTranslationKey,
      );
      if (suggestedQuery != null) {
        searchAssistMessage = 'Did you mean "$suggestedQuery"?';
      } else {
        searchAssistMessage = null;
      }
      return;
    }

    searchAssistMessage = null;
    suggestedQuery = null;
  }

  Future<void> _loadCurrentSurah() async {
    currentAyahs = await _repository.getSurahAyahs(
      _selectedSurahNumber,
      translationKey: downloadedTranslationKey,
    );
  }

  Future<void> _refreshLocalState() async {
    availableTranslations = await _repository.getLocalTranslations(
      languageCode: _catalogLanguageCode,
    );
    sourceVersions = await _repository.getSourceVersions();
    _selectedTranslationKey = _pickTranslationKey(
      existingKey: _selectedTranslationKey,
      translations: availableTranslations,
    );
  }

  Future<void> _runBusy(Future<void> Function() operation) async {
    isWorking = true;
    notifyListeners();

    try {
      await operation();
    } on SocketException {
      errorMessage =
          'Connect to the internet to finish downloading Quran translations.';
    } catch (error) {
      errorMessage = _friendlyErrorMessage(error);
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> useSuggestedQuery() async {
    final String? suggestion = suggestedQuery;
    if (suggestion == null || suggestion.isEmpty) {
      return;
    }
    _searchQuery = suggestion;
    searchAssistMessage = null;
    suggestedQuery = null;
    await _reloadVisibleContent();
    notifyListeners();
  }

  Future<void> _refreshTranslationCatalogInternal({
    required bool suppressNetworkErrors,
  }) async {
    errorMessage = null;
    try {
      final List<QuranTranslationInfo> translations =
          await _repository.refreshTranslationCatalog(
        languageCode: _catalogLanguageCode,
        localization: _catalogLanguageCode,
      );

      if (translations.isEmpty && _catalogLanguageCode != 'en') {
        _catalogLanguageCode = 'en';
        availableTranslations = await _repository.refreshTranslationCatalog(
          languageCode: 'en',
          localization: 'en',
        );
        statusMessage =
            'No translations were returned for $_preferredLanguageCode, so the catalog fell back to English.';
      } else {
        availableTranslations = translations;
        statusMessage = 'Translation catalog refreshed from QuranEnc.';
      }

      _selectedTranslationKey = _pickTranslationKey(
        existingKey: _selectedTranslationKey,
        translations: availableTranslations,
      );
      await _refreshLocalState();
      await _reloadVisibleContent();
    } on SocketException {
      if (suppressNetworkErrors) {
        errorMessage = null;
        statusMessage =
            'Arabic is ready offline. The phone-language translation will download automatically when the device is back online.';
        return;
      }
      rethrow;
    } catch (error) {
      if (suppressNetworkErrors && _isConnectivityLikeError(error)) {
        errorMessage = null;
        statusMessage =
            'Arabic is ready offline. The phone-language translation will download automatically when the device is back online.';
        return;
      }
      rethrow;
    }
  }

  Future<QuranSyncOutcome> _downloadFullTranslationInternal({
    required String translationKey,
    required String translationTitle,
    required bool suppressNetworkErrors,
    required bool userVisibleProgress,
    required bool allowCancellation,
  }) async {
    try {
      statusMessage = userVisibleProgress
          ? 'Preparing full translation download...'
          : 'Setting up $translationTitle for offline reading...';
      int lastProgressNotice = 0;
      final QuranSyncOutcome outcome = await _repository.syncEntireTranslation(
        translationKey: translationKey,
        onProgress: (int completedSurahs, int totalSurahs) {
          if (!userVisibleProgress &&
              completedSurahs - lastProgressNotice < 20) {
            return;
          }
          if (completedSurahs == totalSurahs || completedSurahs == 1) {
            lastProgressNotice = completedSurahs;
          } else if (completedSurahs - lastProgressNotice >= 20) {
            lastProgressNotice = completedSurahs;
          } else {
            return;
          }

          statusMessage =
              'Downloading $translationTitle... $completedSurahs/$totalSurahs surahs';
          notifyListeners();
        },
        shouldCancel:
            allowCancellation ? () => _cancelStartupDownloadRequested : null,
      );
      await _refreshLocalState();
      await _reloadVisibleContent();
      statusMessage = outcome.completed
          ? 'Downloaded ${outcome.insertedVerses} verses for the full $translationTitle.'
          : 'Paused $translationTitle after ${outcome.completedSurahs}/${outcome.totalSurahs} surahs so Quran stays responsive while you use it.';
      return outcome;
    } on SocketException {
      if (suppressNetworkErrors) {
        errorMessage = null;
        statusMessage =
            'Arabic is ready offline. $translationTitle will download automatically when the device is back online.';
        return const QuranSyncOutcome(
          insertedVerses: 0,
          completedSurahs: 0,
          totalSurahs: 114,
        );
      }
      rethrow;
    } catch (error) {
      if (suppressNetworkErrors && _isConnectivityLikeError(error)) {
        errorMessage = null;
        statusMessage =
            'Arabic is ready offline. $translationTitle will download automatically when the device is back online.';
        return const QuranSyncOutcome(
          insertedVerses: 0,
          completedSurahs: 0,
          totalSurahs: 114,
        );
      }
      rethrow;
    }
  }

  bool _isConnectivityLikeError(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network') ||
        message.contains('connection');
  }

  String _friendlyErrorMessage(Object error) {
    if (_isConnectivityLikeError(error)) {
      return 'Connect to the internet to finish downloading Quran translations.';
    }
    return '$error';
  }

  String _normalizeCatalogLanguage(String value) {
    switch (value) {
      case 'ur':
        return 'ur';
      case 'ar':
        return 'ar';
      default:
        return 'en';
    }
  }

  String? _pickTranslationKey({
    required String? existingKey,
    required List<QuranTranslationInfo> translations,
  }) {
    if (translations.isEmpty) {
      return null;
    }

    final bool shouldAutoSelectTranslation = startupSelection?.selectedPackIds
            .contains(AppContentPackIds.quranTranslationDefault) ??
        startupMode != QuranStartupMode.arabicOnly;

    for (final QuranTranslationInfo translation in translations) {
      if (translation.key == existingKey) {
        return existingKey;
      }
    }

    for (final QuranTranslationInfo translation in translations) {
      if (translation.key == 'english_saheeh') {
        return translation.key;
      }
    }

    for (final QuranTranslationInfo translation in translations) {
      if (translation.isDownloaded) {
        return translation.key;
      }
    }

    if (!shouldAutoSelectTranslation) {
      return null;
    }

    return translations.first.key;
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
