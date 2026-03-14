enum FiqhClassification {
  obligatory,
  necessary,
  emphasizedRecommended,
  recommended,
  permissible,
  disliked,
  forbidden,
  disputed;

  String get wireName {
    switch (this) {
      case FiqhClassification.obligatory:
        return 'obligatory';
      case FiqhClassification.necessary:
        return 'necessary';
      case FiqhClassification.emphasizedRecommended:
        return 'emphasized_recommended';
      case FiqhClassification.recommended:
        return 'recommended';
      case FiqhClassification.permissible:
        return 'permissible';
      case FiqhClassification.disliked:
        return 'disliked';
      case FiqhClassification.forbidden:
        return 'forbidden';
      case FiqhClassification.disputed:
        return 'disputed';
    }
  }

  String get label {
    switch (this) {
      case FiqhClassification.obligatory:
        return 'Obligatory';
      case FiqhClassification.necessary:
        return 'Wajib';
      case FiqhClassification.emphasizedRecommended:
        return 'Emphasized Sunnah';
      case FiqhClassification.recommended:
        return 'Recommended';
      case FiqhClassification.permissible:
        return 'Permissible';
      case FiqhClassification.disliked:
        return 'Disliked';
      case FiqhClassification.forbidden:
        return 'Forbidden';
      case FiqhClassification.disputed:
        return 'Disputed';
    }
  }

  static FiqhClassification fromWireName(String value) {
    for (final FiqhClassification classification in FiqhClassification.values) {
      if (classification.wireName == value) {
        return classification;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown fiqh classification.');
  }
}
