import 'package:core/core.dart';
import 'package:prayer/prayer.dart';

import '../domain/fiqh_checklist_item.dart';
import '../domain/fiqh_knowledge_pack.dart';
import '../domain/fiqh_topic.dart';
import 'fiqh_asset_data_source.dart';

class FiqhRepository {
  FiqhRepository({
    FiqhKnowledgeDataSource? dataSource,
  }) : _dataSource = dataSource ?? const FiqhAssetDataSource();

  static const String _providerKey = 'fiqh_pack';

  final FiqhKnowledgeDataSource _dataSource;

  FiqhKnowledgePack? _pack;

  Future<void> initialize() async {
    _pack ??= await _dataSource.loadPack();
  }

  Future<FiqhKnowledgePack> getPack() async {
    await initialize();
    return _pack!;
  }

  Future<List<FiqhTopic>> getTopics() async {
    final List<FiqhTopic> topics = (await getPack()).topics.toList();
    topics
        .sort((FiqhTopic a, FiqhTopic b) => a.sortOrder.compareTo(b.sortOrder));
    return topics;
  }

  Future<List<FiqhChecklistItem>> buildChecklist(FiqhProfile profile) async {
    final List<FiqhChecklistItem> items = <FiqhChecklistItem>[];
    for (final FiqhTopic topic in await getTopics()) {
      if (!topic.showInChecklist) {
        continue;
      }
      final activeRuling = topic.rulingFor(profile.school);
      if (activeRuling == null) {
        continue;
      }
      items.add(
        FiqhChecklistItem(
          topic: topic,
          activeRuling: activeRuling,
        ),
      );
    }
    return items;
  }

  Future<List<FiqhTopic>> getDisputedTopics() async {
    final List<FiqhTopic> topics = await getTopics();
    return topics
        .where((FiqhTopic topic) => topic.showInDisputed)
        .toList(growable: false);
  }

  Future<FiqhTopic?> getTopic(String topicId) async {
    for (final FiqhTopic topic in await getTopics()) {
      if (topic.id == topicId) {
        return topic;
      }
    }
    return null;
  }

  Future<List<SourceVersion>> getSourceVersions() async {
    final FiqhKnowledgePack pack = await getPack();
    return <SourceVersion>[
      SourceVersion(
        providerKey: _providerKey,
        contentKey: 'starter_reference_pack',
        languageCode: 'multi',
        version: pack.displayVersion,
        attribution: pack.attribution,
      ),
    ];
  }
}
