enum RetrievedPassageSourceKind {
  quran,
  hadith;

  String get label {
    switch (this) {
      case RetrievedPassageSourceKind.quran:
        return 'Quran';
      case RetrievedPassageSourceKind.hadith:
        return 'Hadith';
    }
  }
}

class RetrievedPassage {
  const RetrievedPassage({
    required this.sourceKind,
    required this.reference,
    required this.title,
    required this.quote,
    required this.attribution,
    required this.languageCode,
    this.note,
  });

  final RetrievedPassageSourceKind sourceKind;
  final String reference;
  final String title;
  final String quote;
  final String attribution;
  final String languageCode;
  final String? note;
}
