import 'package:prayer/prayer.dart';

class AppStrings {
  const AppStrings._(this.languageCode);

  factory AppStrings.forCode(String languageCode) {
    switch (languageCode) {
      case 'ar':
      case 'ur':
        return AppStrings._(languageCode);
      default:
        return const AppStrings._('en');
    }
  }

  final String languageCode;

  bool get isRtl => languageCode == 'ar' || languageCode == 'ur';

  String _pick({
    required String en,
    required String ar,
    required String ur,
  }) {
    switch (languageCode) {
      case 'ar':
        return ar;
      case 'ur':
        return ur;
      default:
        return en;
    }
  }

  String get appName => 'Ummah App';

  String get homeTab => _pick(en: 'Home', ar: 'الرئيسية', ur: 'ہوم');
  String get prayerTab => _pick(en: 'Prayer', ar: 'الصلاة', ur: 'نماز');
  String get quranTab => _pick(en: 'Quran', ar: 'القرآن', ur: 'قرآن');
  String get qiblaTab => _pick(en: 'Qibla', ar: 'القبلة', ur: 'قبلہ');
  String get moreTab => _pick(en: 'More', ar: 'المزيد', ur: 'مزید');

  String get welcomeTitle => _pick(
        en: 'Welcome to Ummah App',
        ar: 'مرحباً بك في Ummah App',
        ur: 'Ummah App میں خوش آمدید',
      );

  String get welcomeIntro => _pick(
        en: 'Choose your fiqh profile, prayer defaults, location, and which reading packs you want first. You can change them later.',
        ar: 'اختر الملف الفقهي، وإعدادات الصلاة، والموقع، وحزم القراءة التي تريدها أولاً. يمكنك تعديلها لاحقاً.',
        ur: 'اپنا فقہی پروفائل، نماز کی بنیادی ترتیبات، مقام، اور وہ مطالعہ پیک منتخب کریں جو آپ پہلے چاہتے ہیں۔ بعد میں یہ سب بدلا جا سکتا ہے۔',
      );

  String get languageTitle => _pick(en: 'Language', ar: 'اللغة', ur: 'زبان');
  String get fiqhProfileTitle =>
      _pick(en: 'Fiqh Profile', ar: 'الملف الفقهي', ur: 'فقہی پروفائل');
  String get schoolTitle => _pick(en: 'School', ar: 'المذهب', ur: 'مسلک');
  String get schoolHelp => _pick(
        en: 'Most people choose the school their family or local mosque follows.',
        ar: 'غالباً يختار الناس المذهب الذي تتبعه عائلتهم أو مسجدهم المحلي.',
        ur: 'اکثر لوگ وہی مسلک منتخب کرتے ہیں جو ان کے گھر یا مقامی مسجد میں رائج ہو۔',
      );

  String get prayerMethodTitle => _pick(
        en: 'Prayer Calculation Method',
        ar: 'طريقة حساب أوقات الصلاة',
        ur: 'نماز کے اوقات نکالنے کا طریقہ',
      );

  String get notificationsTitle =>
      _pick(en: 'Notifications', ar: 'التنبيهات', ur: 'اطلاعات');
  String get notificationsToggleTitle => _pick(
        en: 'Turn on prayer reminders',
        ar: 'فعّل تذكيرات الصلاة',
        ur: 'نماز کی یاد دہانیاں آن کریں',
      );
  String get notificationsToggleSubtitle => _pick(
        en: 'Ummah App will use the most reliable reminder timing your phone allows.',
        ar: 'سيستخدم التطبيق أدق تذكير تسمح به إعدادات هاتفك.',
        ur: 'ایپ آپ کے فون کے مطابق جتنی قابلِ اعتماد یاد دہانیاں ممکن ہوں گی استعمال کرے گی۔',
      );

  String get locationTitle => _pick(en: 'Location', ar: 'الموقع', ur: 'مقام');
  String get manualLocationTitle => _pick(
        en: 'Closest major city',
        ar: 'أقرب مدينة كبرى',
        ur: 'قریب ترین بڑا شہر',
      );
  String get manualLocationSegmentLabel =>
      _pick(en: 'City', ar: 'مدينة', ur: 'شہر');
  String get deviceGpsLabel => _pick(
        en: 'Use phone location',
        ar: 'استخدم موقع الهاتف',
        ur: 'فون کا مقام استعمال کریں',
      );
  String get gpsSegmentLabel => _pick(en: 'GPS', ar: 'GPS', ur: 'GPS');
  String get manualLocationHelp => _pick(
        en: 'Pick the nearest major city. Ummah App will use that city for prayer times and its local time zone.',
        ar: 'اختر أقرب مدينة كبرى. سيستخدم التطبيق هذه المدينة وتوقيتها المحلي لحساب أوقات الصلاة.',
        ur: 'قریب ترین بڑا شہر منتخب کریں۔ ایپ اسی شہر اور اس کے مقامی ٹائم زون کے مطابق نماز کے اوقات نکالے گی۔',
      );
  String get gpsLocationHelp => _pick(
        en: 'Phone location keeps times aligned as you travel, but it will ask for location permission.',
        ar: 'موقع الهاتف يحدّث الأوقات أثناء السفر، لكنه سيطلب إذن الموقع.',
        ur: 'فون کا مقام سفر کے دوران اوقات کو درست رکھتا ہے، لیکن اس کے لیے لوکیشن کی اجازت درکار ہوگی۔',
      );

  String get quranSetupTitle =>
      _pick(en: 'Quran Setup', ar: 'إعداد القرآن', ur: 'قرآن سیٹ اپ');
  String get quranSetupHelp => _pick(
        en: 'Choose whether you want Arabic only or an automatic starter translation pack in your app language.',
        ar: 'اختر بين العربية فقط أو حزمة ترجمة ابتدائية تلقائية بلغة التطبيق.',
        ur: 'یہ منتخب کریں کہ آپ صرف عربی چاہتے ہیں یا ایپ کی زبان میں خودکار ابتدائی ترجمہ پیک۔',
      );
  String get quranArabicOnly => _pick(
        en: 'Arabic only for now',
        ar: 'العربية فقط حالياً',
        ur: 'فی الحال صرف عربی',
      );
  String get quranStarterPack => _pick(
        en: 'Starter translation pack',
        ar: 'حزمة ترجمة مبدئية',
        ur: 'ابتدائی ترجمہ پیک',
      );
  String get quranArabicOnlyDescription => _pick(
        en: 'Smallest setup. Add translations later when you need them.',
        ar: 'أخف إعداد. أضف الترجمات لاحقاً عند الحاجة.',
        ur: 'سب سے ہلکا سیٹ اپ۔ ضرورت پڑنے پر بعد میں ترجمے شامل کریں۔',
      );
  String get quranStarterPackDescription => _pick(
        en: 'Automatically fetch translation options and preload popular surahs the first time you open Quran.',
        ar: 'سيتم جلب خيارات الترجمة وتحميل السور المشهورة تلقائياً عند فتح القرآن لأول مرة.',
        ur: 'جب آپ پہلی بار قرآن کھولیں گے تو ترجمے کے اختیارات اور مشہور سورتیں خودکار طور پر لوڈ ہو جائیں گی۔',
      );

  String get continueLabel =>
      _pick(en: 'Continue', ar: 'متابعة', ur: 'جاری رکھیں');
  String get actionNeededTitle =>
      _pick(en: 'Action needed', ar: 'إجراء مطلوب', ur: 'کارروائی درکار');
  String get nextPrayerTitle =>
      _pick(en: 'Next prayer', ar: 'الصلاة التالية', ur: 'اگلی نماز');
  String get allPrayersPassedMessage => _pick(
        en: 'All prayers for today have passed.',
        ar: 'انتهت صلوات اليوم كلها.',
        ur: 'آج کی تمام نمازیں گزر چکی ہیں۔',
      );
  String get profilePrefix => _pick(en: 'Profile', ar: 'الملف', ur: 'پروفائل');
  String get methodPrefix => _pick(en: 'Method', ar: 'الطريقة', ur: 'طریقہ');
  String get notificationHealthTitle => _pick(
        en: 'Notification health',
        ar: 'حالة التنبيهات',
        ur: 'اطلاعات کی حالت',
      );
  String get notificationsPendingSetup => _pick(
        en: 'Notifications will be scheduled after onboarding completes.',
        ar: 'سيتم جدولة التنبيهات بعد إكمال الإعداد الأولي.',
        ur: 'ابتدائی سیٹ اپ مکمل ہونے کے بعد اطلاعات شیڈول ہوں گی۔',
      );
  String get locationModeTitle =>
      _pick(en: 'Location mode', ar: 'وضع الموقع', ur: 'مقام کا طریقہ');
  String get manualModeLabel =>
      _pick(en: 'Manual city', ar: 'المدينة المختارة', ur: 'منتخب شہر');
  String get deviceGpsShort =>
      _pick(en: 'Phone GPS', ar: 'GPS الهاتف', ur: 'فون GPS');
  String get refreshGpsLabel =>
      _pick(en: 'Refresh GPS', ar: 'تحديث GPS', ur: 'GPS تازہ کریں');
  String get refreshNotificationsLabel => _pick(
        en: 'Refresh notifications',
        ar: 'تحديث التنبيهات',
        ur: 'اطلاعات تازہ کریں',
      );
  String get offlineFirstStatusTitle => _pick(
        en: 'Offline-first status',
        ar: 'حالة العمل دون اتصال',
        ur: 'آف لائن حالت',
      );
  String get offlineFirstStatusMessage => _pick(
        en: 'Prayer times, qibla bearing, settings, and notification planning all work on-device. Manual city mode stays private and uses the city you selected.',
        ar: 'تعمل أوقات الصلاة واتجاه القبلة والإعدادات وخطة التنبيهات على الجهاز نفسه. وضع المدينة اليدوي يبقى خاصاً ويستخدم المدينة التي اخترتها.',
        ur: 'نماز کے اوقات، قبلہ رخ، سیٹنگز اور اطلاعات کی منصوبہ بندی سب ڈیوائس پر کام کرتی ہیں۔ دستی شہر والا موڈ نجی رہتا ہے اور آپ کے منتخب کردہ شہر کو استعمال کرتا ہے۔',
      );
  String get healthyLabel => _pick(en: 'Good', ar: 'جيد', ur: 'اچھی');
  String get needsRefreshLabel =>
      _pick(en: 'Open app soon', ar: 'افتح التطبيق قريباً', ur: 'جلد کھولیں');
  String get criticalLabel =>
      _pick(en: 'Action needed', ar: 'إجراء مطلوب', ur: 'کارروائی درکار');

  String get quranReaderTitle =>
      _pick(en: 'Quran Reader', ar: 'قارئ القرآن', ur: 'قرآن ریڈر');
  String get quranSearchLabel => _pick(
        en: 'Search Quran Arabic or downloaded translation',
        ar: 'ابحث في نص القرآن أو الترجمة التي تم تنزيلها',
        ur: 'قرآن کے عربی متن یا ڈاؤن لوڈ شدہ ترجمے میں تلاش کریں',
      );
  String get quranSearchHint => _pick(
      en: 'Try رحيم or mercy',
      ar: 'جرّب رحيم أو رحمة',
      ur: 'رحيم یا mercy تلاش کریں');
  String get quranSearchHelp => _pick(
        en: 'Arabic text is bundled offline. Translation search works after that translation has been downloaded.',
        ar: 'النص العربي مرفق دون اتصال. البحث في الترجمة يعمل بعد تنزيل تلك الترجمة.',
        ur: 'عربی متن آف لائن شامل ہے۔ ترجمے میں تلاش اس وقت کام کرے گی جب وہ ترجمہ ڈاؤن لوڈ ہو جائے۔',
      );
  String get translationCacheTitle => _pick(
        en: 'Translation cache',
        ar: 'ذاكرة الترجمة',
        ur: 'ترجمہ کیش',
      );
  String get translationLabel =>
      _pick(en: 'Translation', ar: 'الترجمة', ur: 'ترجمہ');
  String get arabicOnlyLabel =>
      _pick(en: 'Arabic only', ar: 'العربية فقط', ur: 'صرف عربی');
  String get refreshCatalogLabel => _pick(
        en: 'Check translations',
        ar: 'تحقق من الترجمات',
        ur: 'ترجمے دیکھیں',
      );
  String get downloadCurrentSurahLabel => _pick(
        en: 'Download this surah',
        ar: 'نزّل هذه السورة',
        ur: 'یہ سورت ڈاؤن لوڈ کریں',
      );
  String get downloadPopularSurahsLabel => _pick(
        en: 'Download starter pack',
        ar: 'نزّل الحزمة المبدئية',
        ur: 'ابتدائی پیک ڈاؤن لوڈ کریں',
      );
  String get quranTranslationHelp => _pick(
        en: 'Choose a QuranEnc translation when you want offline translated verses.',
        ar: 'اختر ترجمة من QuranEnc عندما تريد آيات مترجمة دون اتصال.',
        ur: 'جب آپ آف لائن ترجمہ شدہ آیات چاہتے ہوں تو QuranEnc کا ترجمہ منتخب کریں۔',
      );
  String get sourcesVersionsTitle => _pick(
        en: 'Sources & versions',
        ar: 'المصادر والإصدارات',
        ur: 'ذرائع اور ورژنز',
      );
  String get attentionNeededTitle => _pick(
        en: 'Attention needed',
        ar: 'يلزم الانتباه',
        ur: 'توجہ درکار ہے',
      );
  String get quranSyncStatusTitle => _pick(
        en: 'Quran sync status',
        ar: 'حالة مزامنة القرآن',
        ur: 'قرآن ہم آہنگی کی حالت',
      );
  String get noMatchesYetTitle => _pick(
        en: 'No matches yet',
        ar: 'لا توجد نتائج بعد',
        ur: 'ابھی کوئی نتیجہ نہیں',
      );
  String get noMatchesYetMessage => _pick(
        en: 'Try a broader Arabic root, an English keyword, or download a translation before searching translated text.',
        ar: 'جرّب جذراً عربياً أوسع أو كلمة إنجليزية أو نزّل ترجمة قبل البحث في النص المترجم.',
        ur: 'کسی وسیع عربی جڑ، انگریزی لفظ، یا ترجمہ ڈاؤن لوڈ کرنے کے بعد تلاش آزمائیں۔',
      );
  String get sourcesVersionsHelp => _pick(
        en: 'Bundled Arabic stays verbatim from Tanzil. Downloaded translations stay verbatim from QuranEnc and are version-tagged locally.',
        ar: 'يبقى النص العربي المرفق مطابقاً لنص Tanzil. وتبقى الترجمات المنزلة مطابقة لنص QuranEnc مع حفظ الإصدار محلياً.',
        ur: 'شامل شدہ عربی متن Tanzil سے لفظ بہ لفظ رکھا جاتا ہے۔ ڈاؤن لوڈ شدہ ترجمے QuranEnc سے بغیر تبدیلی کے محفوظ کیے جاتے ہیں اور ان کا ورژن بھی ساتھ رکھا جاتا ہے۔',
      );
  String get noTranslationVersionsLabel => _pick(
        en: 'No translation versions have been cached yet.',
        ar: 'لم يتم حفظ أي إصدار ترجمة بعد.',
        ur: 'ابھی تک کسی ترجمے کا ورژن محفوظ نہیں ہوا۔',
      );

  String schoolLabel(SchoolOfThought school) {
    switch (school) {
      case SchoolOfThought.hanafi:
        return 'Hanafi';
      case SchoolOfThought.maliki:
        return 'Maliki';
      case SchoolOfThought.shafii:
        return 'Shafi‘i';
      case SchoolOfThought.hanbali:
        return 'Hanbali';
      case SchoolOfThought.jafari:
        return 'Ja‘fari';
    }
  }

  String schoolDescription(SchoolOfThought school) {
    switch (school) {
      case SchoolOfThought.hanafi:
        return _pick(
          en: 'Common in South Asia, Turkey, and many diaspora communities; Hanafi Asr starts a bit later.',
          ar: 'شائع في جنوب آسيا وتركيا وكثير من الجاليات؛ ويكون وقت العصر فيه متأخراً قليلاً.',
          ur: 'یہ برصغیر، ترکی اور بہت سی کمیونٹیز میں عام ہے؛ اس میں عصر کا وقت تھوڑا دیر سے شروع ہوتا ہے۔',
        );
      case SchoolOfThought.maliki:
        return _pick(
          en: 'Common in North and West Africa; close to the broader Sunni standard for daily prayer times.',
          ar: 'شائع في شمال وغرب إفريقيا؛ وهو قريب من المعتمد السني العام في الأوقات اليومية.',
          ur: 'یہ شمالی اور مغربی افریقہ میں عام ہے؛ روزمرہ نماز کے اوقات میں عمومی سنی طریقے کے قریب ہے۔',
        );
      case SchoolOfThought.shafii:
        return _pick(
          en: 'Common in East Africa, Yemen, Southeast Asia, and many global mosque timetables.',
          ar: 'شائع في شرق إفريقيا واليمن وجنوب شرق آسيا، وتعتمده جداول كثيرة حول العالم.',
          ur: 'یہ مشرقی افریقہ، یمن، جنوب مشرقی ایشیا اور بہت سے عالمی مساجد کے شیڈول میں عام ہے۔',
        );
      case SchoolOfThought.hanbali:
        return _pick(
          en: 'Common in parts of the Gulf; daily prayer times are usually close to other Sunni schools.',
          ar: 'شائع في بعض دول الخليج؛ وأوقات الصلاة اليومية فيه قريبة غالباً من بقية المذاهب السنية.',
          ur: 'یہ خلیج کے بعض علاقوں میں عام ہے؛ روزانہ نماز کے اوقات عموماً دوسرے سنی مسالک کے قریب ہوتے ہیں۔',
        );
      case SchoolOfThought.jafari:
        return _pick(
          en: 'The main Twelver Shia school; Maghrib and Isha conventions differ from common Sunni defaults.',
          ar: 'هو المذهب الرئيس عند الإمامية الاثني عشرية؛ وتختلف فيه بعض ضوابط المغرب والعشاء عن الشائع السني.',
          ur: 'یہ اثنا عشری شیعہ کا بنیادی مسلک ہے؛ اس میں مغرب اور عشاء کے بعض اصول عام سنی طریقے سے مختلف ہوتے ہیں۔',
        );
    }
  }

  String methodLabel(PrayerCalculationMethod method) {
    switch (method) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return 'Muslim World League';
      case PrayerCalculationMethod.egyptian:
        return 'Egyptian General Authority';
      case PrayerCalculationMethod.karachi:
        return 'Karachi';
      case PrayerCalculationMethod.northAmerica:
        return 'North America';
      case PrayerCalculationMethod.ummAlQura:
        return 'Umm al-Qura';
      case PrayerCalculationMethod.jafari:
        return 'Ja‘fari';
    }
  }

  String methodDescription(PrayerCalculationMethod method) {
    switch (method) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return _pick(
          en: 'A common global default used by many mosques and prayer apps.',
          ar: 'خيار عالمي شائع تستخدمه مساجد كثيرة وتطبيقات مواقيت الصلاة.',
          ur: 'یہ ایک عام عالمی طریقہ ہے جسے بہت سی مساجد اور نماز ایپس استعمال کرتی ہیں۔',
        );
      case PrayerCalculationMethod.egyptian:
        return _pick(
          en: 'Often used in Egypt and in communities that follow Egyptian prayer tables.',
          ar: 'يُستخدم كثيراً في مصر وفي الجهات التي تعتمد جداولها.',
          ur: 'یہ مصر اور ان کمیونٹیز میں عام ہے جو مصری اوقاتِ نماز کے شیڈول پر چلتی ہیں۔',
        );
      case PrayerCalculationMethod.karachi:
        return _pick(
          en: 'Common in South Asia and often preferred in Hanafi-oriented communities.',
          ar: 'شائع في جنوب آسيا ويُفضَّل كثيراً في البيئات الحنفية.',
          ur: 'یہ برصغیر میں عام ہے اور حنفی ماحول میں اکثر پسند کیا جاتا ہے۔',
        );
      case PrayerCalculationMethod.northAmerica:
        return _pick(
          en: 'A lighter-angle method commonly used by many US and Canada schedules.',
          ar: 'طريقة بزوايا أخف وتُستخدم في كثير من جداول أمريكا الشمالية.',
          ur: 'یہ نسبتاً ہلکے زاویوں والا طریقہ ہے جو امریکہ اور کینیڈا کے بہت سے شیڈول میں استعمال ہوتا ہے۔',
        );
      case PrayerCalculationMethod.ummAlQura:
        return _pick(
          en: 'Widely used in Saudi timetables; Isha is commonly set by minutes after Maghrib.',
          ar: 'تُستخدم كثيراً في الجداول السعودية؛ وغالباً يُحدَّد العشاء بعد دقائق من المغرب.',
          ur: 'یہ سعودی اوقات میں عام ہے؛ عشاء اکثر مغرب کے کچھ منٹ بعد مقرر کی جاتی ہے۔',
        );
      case PrayerCalculationMethod.jafari:
        return _pick(
          en: 'The standard Ja‘fari method used for Twelver Shia prayer timetables.',
          ar: 'الطريقة الجعفرية المعتمدة في جداول الصلاة عند الإمامية الاثني عشرية.',
          ur: 'یہ جعفری طریقہ ہے جو اثنا عشری شیعہ اوقاتِ نماز میں استعمال ہوتا ہے۔',
        );
    }
  }
}
