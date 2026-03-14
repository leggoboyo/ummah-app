import 'package:prayer/prayer.dart';

import 'evidence_reference.dart';
import 'fiqh_classification.dart';

class FiqhRuling {
  const FiqhRuling({
    required this.applicableSchools,
    required this.classification,
    required this.summary,
    required this.notes,
    required this.contextChanges,
    required this.evidence,
  });

  final List<SchoolOfThought> applicableSchools;
  final FiqhClassification classification;
  final String summary;
  final String notes;
  final String contextChanges;
  final List<EvidenceReference> evidence;

  factory FiqhRuling.fromJson(Map<String, dynamic> json) {
    return FiqhRuling(
      applicableSchools: (json['schoolProfiles'] as List<dynamic>)
          .map(
            (dynamic value) => SchoolOfThought.values.firstWhere(
              (SchoolOfThought school) => school.name == value,
            ),
          )
          .toList(growable: false),
      classification: FiqhClassification.fromWireName(
        json['classification'] as String,
      ),
      summary: json['summary'] as String,
      notes: json['notes'] as String,
      contextChanges: json['contextChanges'] as String,
      evidence: (json['evidence'] as List<dynamic>)
          .map(
            (dynamic entry) =>
                EvidenceReference.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  bool appliesTo(SchoolOfThought school) {
    return applicableSchools.contains(school);
  }
}
