import 'scholar_feed_item.dart';

class ScholarFeedSyncResult {
  const ScholarFeedSyncResult({
    required this.items,
    required this.followedSourceIds,
    required this.lastSyncedAt,
  });

  final List<ScholarFeedItem> items;
  final Set<String> followedSourceIds;
  final DateTime? lastSyncedAt;
}
