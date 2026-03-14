import 'fiqh_topic.dart';

class FiqhKnowledgePack {
  const FiqhKnowledgePack({
    required this.version,
    required this.displayVersion,
    required this.attribution,
    required this.disclaimer,
    required this.topics,
  });

  final String version;
  final String displayVersion;
  final String attribution;
  final String disclaimer;
  final List<FiqhTopic> topics;

  factory FiqhKnowledgePack.fromJson(Map<String, dynamic> json) {
    return FiqhKnowledgePack(
      version: json['version'] as String,
      displayVersion: json['displayVersion'] as String,
      attribution: json['attribution'] as String,
      disclaimer: json['disclaimer'] as String,
      topics: (json['topics'] as List<dynamic>)
          .map(
            (dynamic entry) =>
                FiqhTopic.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}
