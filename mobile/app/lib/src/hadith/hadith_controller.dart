import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:hadith/hadith.dart';

class HadithController extends ChangeNotifier {
  HadithController({
    HadithRepository? repository,
    ShiaHadithPackProvider? shiaProvider,
  })  : _repository = repository ?? HadithRepository(),
        _shiaProvider = shiaProvider ?? const PlaceholderShiaHadithPackProvider();

  final HadithRepository _repository;
  final ShiaHadithPackProvider _shiaProvider;

  bool isReady = false;
  bool isWorking = false;
  String? errorMessage;
  String? statusMessage;

  String _activeLanguageCode = 'en';
  String _searchQuery = '';
  int? _selectedCategoryId;

  List<HadithLanguage> languages = const <HadithLanguage>[];
  List<HadithCategory> categories = const <HadithCategory>[];
  List<HadithSearchResult> cachedHadiths = const <HadithSearchResult>[];
  List<HadithSearchResult> searchResults = const <HadithSearchResult>[];
  List<SourceVersion> sourceVersions = const <SourceVersion>[];
  ShiaHadithPackAvailability? shiaAvailability;

  String get activeLanguageCode => _activeLanguageCode;

  String get searchQuery => _searchQuery;

  int? get selectedCategoryId => _selectedCategoryId;

  HadithCategory? get selectedCategory {
    final int? categoryId = _selectedCategoryId;
    if (categoryId == null) {
      return null;
    }
    for (final HadithCategory category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
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
      languages = await _repository.refreshLanguages();
      shiaAvailability = await _shiaProvider.getAvailability();
      _activeLanguageCode = _pickLanguageCode(
        preferredLanguageCode: preferredLanguageCode,
        availableLanguages: languages,
      );
      categories = await _repository.refreshRootCategories(
        languageCode: _activeLanguageCode,
      );
      _selectedCategoryId = categories.isEmpty ? null : categories.first.id;
      sourceVersions = await _repository.getSourceVersions();
      await _reloadVisibleContent();
      isReady = true;
    } catch (error) {
      errorMessage = 'Hadith module failed to initialize: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> refreshCategories() async {
    await _runBusy(() async {
      errorMessage = null;
      categories = await _repository.refreshRootCategories(
        languageCode: _activeLanguageCode,
      );
      if (_selectedCategoryId == null && categories.isNotEmpty) {
        _selectedCategoryId = categories.first.id;
      }
      await _refreshLocalState();
      await _reloadVisibleContent();
      statusMessage = 'Hadith categories refreshed from HadeethEnc.';
    });
  }

  Future<void> selectCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    errorMessage = null;
    statusMessage = null;
    await _reloadVisibleContent();
    notifyListeners();
  }

  Future<void> updateSearchQuery(String value) async {
    _searchQuery = value;
    errorMessage = null;
    statusMessage = null;
    await _reloadVisibleContent();
    notifyListeners();
  }

  Future<void> downloadSelectedCategory() async {
    final HadithCategory? category = selectedCategory;
    if (category == null) {
      errorMessage = 'Choose a category first.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final HadithCategorySyncResult result = await _repository.syncCategory(
        languageCode: _activeLanguageCode,
        categoryId: category.id,
      );
      await _refreshLocalState();
      await _reloadVisibleContent();
      statusMessage =
          'Downloaded ${result.hadithCount} hadith entries for ${category.title}.';
    });
  }

  Future<HadithDetail?> loadHadithDetail(int hadithId) {
    return _repository.getHadithDetail(
      languageCode: _activeLanguageCode,
      hadithId: hadithId,
    );
  }

  Future<void> _reloadVisibleContent() async {
    final int? categoryId = _selectedCategoryId;
    if (_searchQuery.trim().isEmpty) {
      searchResults = const <HadithSearchResult>[];
      cachedHadiths = categoryId == null
          ? const <HadithSearchResult>[]
          : await _repository.getCachedHadithsForCategory(
              languageCode: _activeLanguageCode,
              categoryId: categoryId,
            );
      return;
    }

    cachedHadiths = const <HadithSearchResult>[];
    searchResults = await _repository.search(
      query: _searchQuery,
      languageCode: _activeLanguageCode,
    );
  }

  Future<void> _refreshLocalState() async {
    categories = await _repository.getRootCategories(
      languageCode: _activeLanguageCode,
    );
    sourceVersions = await _repository.getSourceVersions();
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

  String _pickLanguageCode({
    required String preferredLanguageCode,
    required List<HadithLanguage> availableLanguages,
  }) {
    const List<String> fallbacks = <String>['en', 'ar', 'ur'];
    for (final HadithLanguage language in availableLanguages) {
      if (language.code == preferredLanguageCode) {
        return preferredLanguageCode;
      }
    }
    for (final String fallback in fallbacks) {
      for (final HadithLanguage language in availableLanguages) {
        if (language.code == fallback) {
          return fallback;
        }
      }
    }
    return availableLanguages.isEmpty ? 'en' : availableLanguages.first.code;
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
