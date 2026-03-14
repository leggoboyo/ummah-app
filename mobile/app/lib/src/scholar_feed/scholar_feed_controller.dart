import 'package:flutter/foundation.dart';
import 'package:scholar_feed/scholar_feed.dart';

import '../bootstrap/shared_preferences_key_value_store.dart';

class ScholarFeedController extends ChangeNotifier {
  ScholarFeedController({
    ScholarFeedRepository? repository,
  }) : _repository = repository ??
            ScholarFeedRepository(
              keyValueStore: SharedPreferencesKeyValueStore(),
            );

  final ScholarFeedRepository _repository;

  bool isReady = false;
  bool isWorking = false;
  String? errorMessage;
  String? statusMessage;

  List<ScholarFeedSource> availableSources = const <ScholarFeedSource>[];
  List<ScholarFeedItem> cachedItems = const <ScholarFeedItem>[];
  Set<String> followedSourceIds = <String>{};
  DateTime? lastSyncedAt;

  Future<void> initialize() async {
    if (isReady || isWorking) {
      return;
    }

    isWorking = true;
    notifyListeners();
    try {
      availableSources = await _repository.getAvailableSources();
      final ScholarFeedSyncResult cached = await _repository.getCachedFeed();
      cachedItems = cached.items;
      followedSourceIds = cached.followedSourceIds;
      lastSyncedAt = cached.lastSyncedAt;
      isReady = true;
    } catch (error) {
      errorMessage = 'Scholar feed failed to initialize: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  bool isFollowed(String sourceId) {
    return followedSourceIds.contains(sourceId);
  }

  Future<void> toggleSource({
    required String sourceId,
    required bool isFollowed,
  }) async {
    await _repository.setSourceFollowed(
      sourceId: sourceId,
      isFollowed: isFollowed,
    );
    followedSourceIds = await _repository.getFollowedSourceIds();
    notifyListeners();
  }

  Future<void> refresh() async {
    isWorking = true;
    errorMessage = null;
    notifyListeners();
    try {
      final ScholarFeedSyncResult result =
          await _repository.refreshFollowedSources();
      cachedItems = result.items;
      followedSourceIds = result.followedSourceIds;
      lastSyncedAt = result.lastSyncedAt;
      statusMessage = 'Feed metadata refreshed from followed public sources.';
    } catch (error) {
      errorMessage = '$error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  Future<void> close() async {
    await _repository.dispose();
  }
}
