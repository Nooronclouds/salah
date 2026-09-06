import 'package:salah/models/prayer.dart';

/// One day's journal page: prayer statuses, gratitude lines, a reflection, and
/// any attached photo file paths. Immutable — mutate via [copyWith].
class JournalEntry {
  const JournalEntry({
    required this.dateKey,
    this.statuses = const {},
    this.gratitude = const [],
    this.reflection = '',
    this.photoPaths = const [],
  });

  /// Day identity, formatted yyyy-MM-dd.
  final String dateKey;
  final Map<Prayer, PrayerStatus> statuses;
  final List<String> gratitude;
  final String reflection;
  final List<String> photoPaths;

  /// A blank page for [dateKey].
  factory JournalEntry.empty(String dateKey) => JournalEntry(dateKey: dateKey);

  PrayerStatus statusOf(Prayer prayer) =>
      statuses[prayer] ?? PrayerStatus.pending;

  JournalEntry copyWith({
    Map<Prayer, PrayerStatus>? statuses,
    List<String>? gratitude,
    String? reflection,
    List<String>? photoPaths,
  }) {
    return JournalEntry(
      dateKey: dateKey,
      statuses: statuses ?? this.statuses,
      gratitude: gratitude ?? this.gratitude,
      reflection: reflection ?? this.reflection,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'statuses': {
          for (final entry in statuses.entries) entry.key.name: entry.value.name,
        },
        'gratitude': gratitude,
        'reflection': reflection,
        'photoPaths': photoPaths,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final rawStatuses = (json['statuses'] as Map?) ?? const {};
    return JournalEntry(
      dateKey: json['dateKey'] as String,
      statuses: {
        for (final entry in rawStatuses.entries)
          if (_prayerByName(entry.key as String) case final Prayer prayer)
            if (_statusByName(entry.value as String) case final PrayerStatus s)
              prayer: s,
      },
      gratitude: List<String>.from((json['gratitude'] as List?) ?? const []),
      reflection: (json['reflection'] as String?) ?? '',
      photoPaths: List<String>.from((json['photoPaths'] as List?) ?? const []),
    );
  }

  static Prayer? _prayerByName(String name) {
    for (final prayer in Prayer.values) {
      if (prayer.name == name) return prayer;
    }
    return null;
  }

  static PrayerStatus? _statusByName(String name) {
    for (final status in PrayerStatus.values) {
      if (status.name == name) return status;
    }
    return null;
  }
}
