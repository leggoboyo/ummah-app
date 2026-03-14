import 'package:core/core.dart';
import 'package:fiqh/fiqh.dart';
import 'package:flutter/foundation.dart';
import 'package:prayer/prayer.dart';

import 'fiqh_progress_store.dart';

class FiqhController extends ChangeNotifier {
  FiqhController({
    required this.fiqhProfile,
    FiqhRepository? repository,
    FiqhChecklistProgressStore? progressStore,
    DateTime Function()? nowProvider,
  })  : _repository = repository ?? FiqhRepository(),
        _progressStore =
            progressStore ?? SharedPreferencesFiqhChecklistProgressStore(),
        _nowProvider = nowProvider ?? DateTime.now;

  final FiqhProfile fiqhProfile;
  final FiqhRepository _repository;
  final FiqhChecklistProgressStore _progressStore;
  final DateTime Function() _nowProvider;

  bool isReady = false;
  bool isWorking = false;
  String? errorMessage;
  String? statusMessage;

  FiqhKnowledgePack? _pack;
  List<FiqhTopic> topics = const <FiqhTopic>[];
  List<FiqhTopic> disputedTopics = const <FiqhTopic>[];
  List<FiqhChecklistItem> checklistItems = const <FiqhChecklistItem>[];
  List<SourceVersion> sourceVersions = const <SourceVersion>[];
  Set<String> completedChecklistItemIds = <String>{};
  String? _selectedComparisonTopicId;

  String? get selectedComparisonTopicId => _selectedComparisonTopicId;

  FiqhKnowledgePack? get pack => _pack;

  DateTime get checklistDate => _truncateDate(_nowProvider());

  FiqhTopic? get selectedComparisonTopic {
    final String? topicId = _selectedComparisonTopicId;
    if (topicId == null) {
      return null;
    }
    for (final FiqhTopic topic in topics) {
      if (topic.id == topicId) {
        return topic;
      }
    }
    return null;
  }

  Future<void> initialize() async {
    if (isReady || isWorking) {
      return;
    }

    isWorking = true;
    notifyListeners();

    try {
      await _repository.initialize();
      _pack = await _repository.getPack();
      topics = await _repository.getTopics();
      disputedTopics = await _repository.getDisputedTopics();
      checklistItems = await _repository.buildChecklist(fiqhProfile);
      sourceVersions = await _repository.getSourceVersions();
      completedChecklistItemIds = await _progressStore.load(
        date: checklistDate,
        profile: fiqhProfile,
      );
      _selectedComparisonTopicId = _pickInitialComparisonTopicId();
      isReady = true;
    } catch (error) {
      errorMessage = 'Fiqh guide failed to initialize: $error';
    } finally {
      isWorking = false;
      notifyListeners();
    }
  }

  bool isCompleted(String topicId) {
    return completedChecklistItemIds.contains(topicId);
  }

  Future<void> toggleChecklistItem({
    required String topicId,
    required bool isCompleted,
  }) async {
    final Set<String> updated = Set<String>.from(completedChecklistItemIds);
    if (isCompleted) {
      updated.add(topicId);
    } else {
      updated.remove(topicId);
    }
    completedChecklistItemIds = updated;
    notifyListeners();

    await _progressStore.save(
      date: checklistDate,
      profile: fiqhProfile,
      completedTopicIds: completedChecklistItemIds,
    );
  }

  void selectComparisonTopic(String? topicId) {
    if (topicId == null || topicId.isEmpty) {
      return;
    }
    _selectedComparisonTopicId = topicId;
    notifyListeners();
  }

  String _pickInitialComparisonTopicId() {
    if (disputedTopics.isNotEmpty) {
      return disputedTopics.first.id;
    }
    if (topics.isNotEmpty) {
      return topics.first.id;
    }
    return '';
  }

  DateTime _truncateDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
