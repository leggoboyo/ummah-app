import 'package:core/core.dart';

enum AssistantMode {
  quran,
  hadith;

  String get title {
    switch (this) {
      case AssistantMode.quran:
        return 'Ask Quran AI';
      case AssistantMode.hadith:
        return 'Ask Hadith AI';
    }
  }

  String get label {
    switch (this) {
      case AssistantMode.quran:
        return 'Quran';
      case AssistantMode.hadith:
        return 'Hadith';
    }
  }

  AppEntitlement get requiredEntitlement {
    switch (this) {
      case AssistantMode.quran:
        return AppEntitlement.aiQuran;
      case AssistantMode.hadith:
        return AppEntitlement.aiHadith;
    }
  }
}
