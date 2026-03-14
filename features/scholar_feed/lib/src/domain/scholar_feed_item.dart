class ScholarFeedItem {
  const ScholarFeedItem({
    required this.id,
    required this.sourceId,
    required this.sourceTitle,
    required this.providerName,
    required this.title,
    required this.summary,
    required this.url,
    required this.languageCode,
    required this.categoryLabel,
    required this.publishedAt,
    this.imageUrl,
  });

  final String id;
  final String sourceId;
  final String sourceTitle;
  final String providerName;
  final String title;
  final String summary;
  final String url;
  final String languageCode;
  final String categoryLabel;
  final DateTime? publishedAt;
  final String? imageUrl;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'sourceId': sourceId,
      'sourceTitle': sourceTitle,
      'providerName': providerName,
      'title': title,
      'summary': summary,
      'url': url,
      'languageCode': languageCode,
      'categoryLabel': categoryLabel,
      'publishedAt': publishedAt?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory ScholarFeedItem.fromJson(Map<String, dynamic> json) {
    return ScholarFeedItem(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      sourceTitle: json['sourceTitle'] as String,
      providerName: json['providerName'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String? ?? '',
      url: json['url'] as String,
      languageCode: json['languageCode'] as String,
      categoryLabel: json['categoryLabel'] as String,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
