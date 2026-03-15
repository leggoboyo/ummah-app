import 'dart:convert';

import 'package:core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class FiqhChecklistProgressStore {
  Future<Set<String>> load({
    required DateTime date,
    required FiqhProfile profile,
  });

  Future<void> save({
    required DateTime date,
    required FiqhProfile profile,
    required Set<String> completedTopicIds,
  });
}

class SharedPreferencesFiqhChecklistProgressStore
    implements FiqhChecklistProgressStore {
  SharedPreferencesFiqhChecklistProgressStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<Set<String>> load({
    required DateTime date,
    required FiqhProfile profile,
  }) async {
    final String? raw = await _preferences.getString(_key(date, profile));
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<String>()
          .where((String value) => value.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> save({
    required DateTime date,
    required FiqhProfile profile,
    required Set<String> completedTopicIds,
  }) {
    final List<String> sortedIds = completedTopicIds.toList()..sort();
    return _preferences.setString(
      _key(date, profile),
      jsonEncode(sortedIds),
    );
  }

  String _key(DateTime date, FiqhProfile profile) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return 'fiqh_checklist_v1_${profile.school.name}_$year-$month-$day';
  }
}
