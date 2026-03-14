enum EvidenceReferenceType {
  quran,
  hadith,
  scholarlyLink;

  String get wireName {
    switch (this) {
      case EvidenceReferenceType.quran:
        return 'quran';
      case EvidenceReferenceType.hadith:
        return 'hadith';
      case EvidenceReferenceType.scholarlyLink:
        return 'scholarly_link';
    }
  }

  static EvidenceReferenceType fromWireName(String value) {
    for (final EvidenceReferenceType type in EvidenceReferenceType.values) {
      if (type.wireName == value) {
        return type;
      }
    }
    throw ArgumentError.value(
        value, 'value', 'Unknown evidence reference type.');
  }
}

class EvidenceReference {
  const EvidenceReference({
    required this.type,
    required this.citation,
    required this.title,
    this.url,
    this.note,
  });

  final EvidenceReferenceType type;
  final String citation;
  final String title;
  final String? url;
  final String? note;

  factory EvidenceReference.fromJson(Map<String, dynamic> json) {
    return EvidenceReference(
      type: EvidenceReferenceType.fromWireName(json['type'] as String),
      citation: json['citation'] as String,
      title: json['title'] as String,
      url: json['url'] as String?,
      note: json['note'] as String?,
    );
  }
}
