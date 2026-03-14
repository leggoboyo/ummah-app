import 'package:prayer/prayer.dart';

import 'fiqh_ruling.dart';

class FiqhTopic {
  const FiqhTopic({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.category,
    required this.summary,
    required this.checklistLabel,
    required this.frequencyLabel,
    required this.showInChecklist,
    required this.showInDisputed,
    required this.scholarEscalation,
    required this.sortOrder,
    required this.rulings,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String category;
  final String summary;
  final String checklistLabel;
  final String frequencyLabel;
  final bool showInChecklist;
  final bool showInDisputed;
  final String scholarEscalation;
  final int sortOrder;
  final List<FiqhRuling> rulings;

  factory FiqhTopic.fromJson(Map<String, dynamic> json) {
    return FiqhTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      shortTitle: json['shortTitle'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String,
      checklistLabel: json['checklistLabel'] as String,
      frequencyLabel: json['frequencyLabel'] as String,
      showInChecklist: json['showInChecklist'] as bool? ?? false,
      showInDisputed: json['showInDisputed'] as bool? ?? false,
      scholarEscalation: json['scholarEscalation'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      rulings: (json['rulings'] as List<dynamic>)
          .map(
            (dynamic entry) =>
                FiqhRuling.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  FiqhRuling? rulingFor(SchoolOfThought school) {
    for (final FiqhRuling ruling in rulings) {
      if (ruling.appliesTo(school)) {
        return ruling;
      }
    }
    return null;
  }
}
