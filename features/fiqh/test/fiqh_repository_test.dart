import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:fiqh/fiqh.dart';
import 'package:test/test.dart';

void main() {
  late FiqhRepository repository;

  setUp(() {
    repository = FiqhRepository(
      dataSource: _FakeFiqhKnowledgeDataSource(),
    );
  });

  test('builds checklist using the selected fiqh profile', () async {
    final List<FiqhChecklistItem> hanafiChecklist =
        await repository.buildChecklist(FiqhProfile(
      tradition: FiqhTradition.sunni,
      school: SchoolOfThought.hanafi,
    ));

    final FiqhChecklistItem witr = hanafiChecklist.firstWhere(
      (FiqhChecklistItem item) => item.id == 'witr_prayer',
    );

    expect(witr.activeRuling.classification, FiqhClassification.necessary);
    expect(hanafiChecklist.length, 4);
  });

  test('returns school-specific disputed rulings', () async {
    final FiqhTopic? seafoodTopic =
        await repository.getTopic('shellfish_and_non_fish_sea_animals');

    expect(seafoodTopic, isNotNull);
    expect(
      seafoodTopic!.rulingFor(SchoolOfThought.hanafi)!.classification,
      FiqhClassification.disputed,
    );
    expect(
      seafoodTopic.rulingFor(SchoolOfThought.shafii)!.classification,
      FiqhClassification.permissible,
    );
    expect(
      seafoodTopic.rulingFor(SchoolOfThought.jafari)!.summary,
      contains('Fish with scales are permitted'),
    );
  });

  test('reports bundled source version metadata', () async {
    final List<SourceVersion> versions = await repository.getSourceVersions();

    expect(versions.single.providerKey, 'fiqh_pack');
    expect(versions.single.version, '2026.03-starter');
  });

  test('bundled knowledge pack keeps evidence references on every ruling',
      () async {
    final File packFile = File('assets/fiqh_knowledge_v1.json');
    final Map<String, dynamic> json = jsonDecode(
      await packFile.readAsString(),
    ) as Map<String, dynamic>;
    final FiqhKnowledgePack pack = FiqhKnowledgePack.fromJson(json);

    expect(pack.topics, isNotEmpty);

    for (final FiqhTopic topic in pack.topics) {
      expect(topic.scholarEscalation, isNotEmpty, reason: topic.id);
      expect(topic.rulings, isNotEmpty, reason: topic.id);
      for (final FiqhRuling ruling in topic.rulings) {
        expect(ruling.evidence, isNotEmpty, reason: topic.id);
        expect(ruling.applicableSchools, isNotEmpty, reason: topic.id);
      }
    }
  });
}

class _FakeFiqhKnowledgeDataSource implements FiqhKnowledgeDataSource {
  @override
  Future<FiqhKnowledgePack> loadPack() async {
    return FiqhKnowledgePack.fromJson(
      jsonDecode(_fakePackJson) as Map<String, dynamic>,
    );
  }
}

const String _fakePackJson = '''
{
  "version": "fiqh_knowledge_v1",
  "displayVersion": "2026.03-starter",
  "attribution": "Curated starter fiqh pack with cited references. This is not a fatwa service.",
  "disclaimer": "Starter pack.",
  "topics": [
    {
      "id": "five_daily_prayers",
      "title": "Five Daily Prayers",
      "shortTitle": "Daily prayers",
      "category": "Daily obligations",
      "summary": "Summary",
      "checklistLabel": "Checklist",
      "frequencyLabel": "Daily",
      "showInChecklist": true,
      "showInDisputed": false,
      "scholarEscalation": "Ask a scholar.",
      "sortOrder": 10,
      "rulings": [
        {
          "schoolProfiles": ["hanafi", "maliki", "shafii", "hanbali", "jafari"],
          "classification": "obligatory",
          "summary": "Perform the prayers.",
          "notes": "Shared rule.",
          "contextChanges": "Excuses matter.",
          "evidence": [
            {
              "type": "quran",
              "citation": "Qur'an 4:103",
              "title": "Prayer at fixed times."
            }
          ]
        }
      ]
    },
    {
      "id": "ramadan_fasting",
      "title": "Ramadan Fasting",
      "shortTitle": "Ramadan fast",
      "category": "Seasonal obligations",
      "summary": "Summary",
      "checklistLabel": "Checklist",
      "frequencyLabel": "Ramadan",
      "showInChecklist": true,
      "showInDisputed": false,
      "scholarEscalation": "Ask a scholar.",
      "sortOrder": 20,
      "rulings": [
        {
          "schoolProfiles": ["hanafi", "maliki", "shafii", "hanbali", "jafari"],
          "classification": "obligatory",
          "summary": "Fast Ramadan.",
          "notes": "Shared rule.",
          "contextChanges": "Excuses matter.",
          "evidence": [
            {
              "type": "quran",
              "citation": "Qur'an 2:183",
              "title": "Fasting is prescribed."
            }
          ]
        }
      ]
    },
    {
      "id": "zakat_al_mal",
      "title": "Zakat al-Mal",
      "shortTitle": "Zakat",
      "category": "Financial obligations",
      "summary": "Summary",
      "checklistLabel": "Checklist",
      "frequencyLabel": "Annual",
      "showInChecklist": true,
      "showInDisputed": false,
      "scholarEscalation": "Ask a scholar.",
      "sortOrder": 30,
      "rulings": [
        {
          "schoolProfiles": ["hanafi", "maliki", "shafii", "hanbali", "jafari"],
          "classification": "obligatory",
          "summary": "Pay zakat when due.",
          "notes": "Shared rule.",
          "contextChanges": "Finances matter.",
          "evidence": [
            {
              "type": "quran",
              "citation": "Qur'an 2:110",
              "title": "Give zakah."
            }
          ]
        }
      ]
    },
    {
      "id": "witr_prayer",
      "title": "Witr Prayer",
      "shortTitle": "Witr",
      "category": "Night worship",
      "summary": "Summary",
      "checklistLabel": "Checklist",
      "frequencyLabel": "Nightly",
      "showInChecklist": true,
      "showInDisputed": true,
      "scholarEscalation": "Ask a scholar.",
      "sortOrder": 40,
      "rulings": [
        {
          "schoolProfiles": ["hanafi"],
          "classification": "necessary",
          "summary": "Witr is wajib.",
          "notes": "Hanafi.",
          "contextChanges": "Timing matters.",
          "evidence": [
            {
              "type": "scholarly_link",
              "citation": "SeekersGuidance",
              "title": "Hanafi Witr",
              "url": "https://example.com/hanafi-witr"
            }
          ]
        },
        {
          "schoolProfiles": ["maliki", "shafii", "hanbali"],
          "classification": "emphasized_recommended",
          "summary": "Witr is emphasized.",
          "notes": "Majority.",
          "contextChanges": "Timing matters.",
          "evidence": [
            {
              "type": "hadith",
              "citation": "Sahih Muslim",
              "title": "Witr reports."
            }
          ]
        },
        {
          "schoolProfiles": ["jafari"],
          "classification": "recommended",
          "summary": "Witr is part of the night prayer.",
          "notes": "Ja'fari.",
          "contextChanges": "Timing matters.",
          "evidence": [
            {
              "type": "scholarly_link",
              "citation": "Sistani",
              "title": "Night prayer",
              "url": "https://example.com/jafari-witr"
            }
          ]
        }
      ]
    },
    {
      "id": "shellfish_and_non_fish_sea_animals",
      "title": "Shellfish and Non-Fish Sea Animals",
      "shortTitle": "Seafood differences",
      "category": "Disputed issues",
      "summary": "Summary",
      "checklistLabel": "Checklist",
      "frequencyLabel": "As needed",
      "showInChecklist": false,
      "showInDisputed": true,
      "scholarEscalation": "Ask a scholar.",
      "sortOrder": 50,
      "rulings": [
        {
          "schoolProfiles": ["hanafi"],
          "classification": "disputed",
          "summary": "Fish are permitted; shellfish usually are not.",
          "notes": "Hanafi.",
          "contextChanges": "Creature type matters.",
          "evidence": [
            {
              "type": "scholarly_link",
              "citation": "SeekersGuidance",
              "title": "Seafood in Hanafi fiqh",
              "url": "https://example.com/hanafi-seafood"
            }
          ]
        },
        {
          "schoolProfiles": ["maliki", "shafii", "hanbali"],
          "classification": "permissible",
          "summary": "Most seafood is permitted.",
          "notes": "Majority.",
          "contextChanges": "Preparation matters.",
          "evidence": [
            {
              "type": "quran",
              "citation": "Qur'an 5:96",
              "title": "Seafood is lawful."
            }
          ]
        },
        {
          "schoolProfiles": ["jafari"],
          "classification": "disputed",
          "summary": "Fish with scales are permitted and shrimp is permitted.",
          "notes": "Ja'fari.",
          "contextChanges": "Creature type matters.",
          "evidence": [
            {
              "type": "scholarly_link",
              "citation": "Sistani",
              "title": "Sea animals",
              "url": "https://example.com/jafari-seafood"
            }
          ]
        }
      ]
    }
  ]
}
''';
