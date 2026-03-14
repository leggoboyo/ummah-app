import 'fiqh_ruling.dart';
import 'fiqh_topic.dart';

class FiqhChecklistItem {
  const FiqhChecklistItem({
    required this.topic,
    required this.activeRuling,
  });

  final FiqhTopic topic;
  final FiqhRuling activeRuling;

  String get id => topic.id;
}
