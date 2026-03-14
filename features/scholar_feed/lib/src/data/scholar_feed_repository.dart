import 'dart:convert';

import 'package:core/core.dart';

import '../domain/scholar_feed_item.dart';
import '../domain/scholar_feed_source.dart';
import '../domain/scholar_feed_sync_result.dart';
import 'islamhouse_rss_data_source.dart';
import 'scholar_feed_defaults.dart';

class ScholarFeedRepository {
  ScholarFeedRepository({
    required KeyValueStore keyValueStore,
    IslamHouseRssDataSource? dataSource,
    List<ScholarFeedSource>? availableSources,
  })  : _keyValueStore = keyValueStore,
        _dataSource = dataSource ?? IslamHouseRssDataSource(),
        _availableSources =
            availableSources ?? buildDefaultScholarFeedSources();

  static const String _cacheKey = 'scholar_feed_cache_v1';
  static const String _followedKey = 'scholar_feed_followed_sources_v1';

  final KeyValueStore _keyValueStore;
  final IslamHouseRssDataSource _dataSource;
  final List<ScholarFeedSource> _availableSources;

  Future<List<ScholarFeedSource>> getAvailableSources() async {
    return _availableSources;
  }

  Future<Set<String>> getFollowedSourceIds() async {
    final String? raw = await _keyValueStore.readString(_followedKey);
    if (raw == null || raw.isEmpty) {
      return _defaultFollowedSourceIds();
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<String>()
          .where((String id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return _defaultFollowedSourceIds();
    }
  }

  Future<void> setSourceFollowed({
    required String sourceId,
    required bool isFollowed,
  }) async {
    final Set<String> followed = await getFollowedSourceIds();
    if (isFollowed) {
      followed.add(sourceId);
    } else {
      followed.remove(sourceId);
    }
    final List<String> sorted = followed.toList()..sort();
    await _keyValueStore.writeString(_followedKey, jsonEncode(sorted));
  }

  Future<ScholarFeedSyncResult> getCachedFeed() async {
    final Set<String> followed = await getFollowedSourceIds();
    final String? raw = await _keyValueStore.readString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return ScholarFeedSyncResult(
        items: const <ScholarFeedItem>[],
        followedSourceIds: followed,
        lastSyncedAt: null,
      );
    }

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final List<ScholarFeedItem> items = (json['items'] as List<dynamic>)
          .map(
            (dynamic value) =>
                ScholarFeedItem.fromJson(value as Map<String, dynamic>),
          )
          .where((ScholarFeedItem item) => followed.contains(item.sourceId))
          .toList(growable: false);
      return ScholarFeedSyncResult(
        items: items,
        followedSourceIds: followed,
        lastSyncedAt: DateTime.tryParse(json['lastSyncedAt'] as String? ?? ''),
      );
    } catch (_) {
      return ScholarFeedSyncResult(
        items: const <ScholarFeedItem>[],
        followedSourceIds: followed,
        lastSyncedAt: null,
      );
    }
  }

  Future<ScholarFeedSyncResult> refreshFollowedSources() async {
    final Set<String> followed = await getFollowedSourceIds();
    final List<ScholarFeedItem> aggregated = <ScholarFeedItem>[];

    for (final ScholarFeedSource source in _availableSources) {
      if (!followed.contains(source.id)) {
        continue;
      }
      aggregated.addAll(await _dataSource.fetchFeed(source));
    }

    aggregated.sort((ScholarFeedItem a, ScholarFeedItem b) {
      final DateTime left =
          a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime right =
          b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });

    final Map<String, ScholarFeedItem> deduped = <String, ScholarFeedItem>{};
    for (final ScholarFeedItem item in aggregated) {
      deduped[item.id] = item;
    }

    final DateTime now = DateTime.now().toUtc();
    final ScholarFeedSyncResult result = ScholarFeedSyncResult(
      items: deduped.values.toList(growable: false),
      followedSourceIds: followed,
      lastSyncedAt: now,
    );
    await _keyValueStore.writeString(
      _cacheKey,
      jsonEncode(<String, Object?>{
        'lastSyncedAt': now.toIso8601String(),
        'items': result.items
            .map((ScholarFeedItem item) => item.toJson())
            .toList(growable: false),
      }),
    );
    return result;
  }

  Future<void> dispose() async {
    _dataSource.dispose();
  }

  Set<String> _defaultFollowedSourceIds() {
    return <String>{
      'islamhouse_en_all',
      'islamhouse_ar_all',
      'islamhouse_ur_all',
    };
  }
}
