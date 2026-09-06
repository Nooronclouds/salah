import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:salah/models/journal_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists one [JournalEntry] per day in local storage (SharedPreferences).
/// Local-first: nothing leaves the device.
class JournalStore {
  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');
  static const String _prefix = 'journal:';

  /// The yyyy-MM-dd key for a date.
  static String keyFor(DateTime date) => _keyFormat.format(date);

  Future<JournalEntry> load(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$dateKey');
    if (raw == null) return JournalEntry.empty(dateKey);
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return JournalEntry.fromJson(json);
    } on FormatException {
      // Corrupt payload — start the day fresh rather than crash.
      return JournalEntry.empty(dateKey);
    }
  }

  Future<void> save(JournalEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix${entry.dateKey}',
      jsonEncode(entry.toJson()),
    );
  }
}
