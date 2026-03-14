import 'scholar_feed_category.dart';

class ScholarFeedSource {
  const ScholarFeedSource({
    required this.id,
    required this.providerKey,
    required this.providerName,
    required this.title,
    required this.description,
    required this.languageCode,
    required this.category,
    required this.feedUrl,
    required this.siteUrl,
    this.requiresApiKey = false,
  });

  final String id;
  final String providerKey;
  final String providerName;
  final String title;
  final String description;
  final String languageCode;
  final ScholarFeedCategory category;
  final String feedUrl;
  final String siteUrl;
  final bool requiresApiKey;
}
