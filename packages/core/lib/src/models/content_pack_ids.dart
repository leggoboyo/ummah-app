class AppContentPackIds {
  static const String corePrayer = 'core_prayer';
  static const String quranArabic = 'quran_arabic';
  static const String quranTranslationDefault = 'quran_translation:default';
  static const String hadithPackDefault = 'hadith_pack:default';
  static const String quranAudioStarter = 'quran_audio:starter';

  static const String smartQuranSearch = 'quran_search:smart';
  static const String basicsLearning = 'learning_pack:basics_islam';
  static const String duaDhikr = 'dua_dhikr:starter';

  static String quranTranslationLanguage(String languageCode) =>
      'quran_translation:$languageCode';

  static String hadithPackLanguage(String languageCode) =>
      'hadith_pack:$languageCode';
}
