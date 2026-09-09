import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salah/models/journal_entry.dart';
import 'package:salah/models/prayer.dart';
import 'package:salah/theme.dart';
import 'package:salah/widgets/garden.dart';

/// The printable keepsake for one day — the "saved page" (PNG/PDF), not a
/// screenshot of the app. Empty sections (reflection, photos) are hidden.
class KeepsakePage extends StatelessWidget {
  const KeepsakePage({
    super.key,
    required this.date,
    required this.entry,
    required this.times,
    required this.locationName,
  });

  final DateTime date;
  final JournalEntry entry;
  final Map<Prayer, DateTime> times;
  final String locationName;

  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _date = DateFormat('EEEE · dd MMMM yyyy');

  List<String> get _gratitude =>
      entry.gratitude.where((g) => g.trim().isNotEmpty).toList();

  bool get _hasReflection => entry.reflection.trim().isNotEmpty;

  List<String> get _photos => entry.photoPaths;

  /// Prayers to show: the five obligatory, plus any optional ones marked done.
  List<Prayer> get _prayers => [
        ...Prayer.obligatory,
        ...Prayer.optional
            .where((p) => entry.statusOf(p) == PrayerStatus.done),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GardenColors.parchment,
        border: Border.all(color: const Color(0xFFE7DCBE)),
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE3D6B2)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SectionHeader('Prayers'),
            _prayersGrid(),
            if (_gratitude.isNotEmpty) ...[
              const SectionHeader('Grateful for today'),
              _gratitudeProse(),
            ],
            if (_hasReflection) ...[
              const SectionHeader('Reflection'),
              _reflectionBlock(),
            ],
            if (_photos.isNotEmpty) ...[
              const SectionHeader('Today in photos'),
              _photosRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photosRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final path in _photos) PhotoThumb(path: path, size: 92),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        const Garland(),
        const SizedBox(height: 4),
        Text('Salah & Gratitude',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(
          '${_date.format(date)} · $locationName',
          textAlign: TextAlign.center,
          style: const TextStyle(color: GardenColors.muted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _prayersGrid() {
    final prayers = _prayers;
    final rows = <Widget>[];
    for (var i = 0; i < prayers.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: _prayerCell(prayers[i])),
          Expanded(
            child: i + 1 < prayers.length
                ? _prayerCell(prayers[i + 1])
                : const SizedBox(),
          ),
        ],
      ));
    }
    return Column(children: rows);
  }

  Widget _prayerCell(Prayer prayer) {
    final status = entry.statusOf(prayer);
    final time = times[prayer];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          PrayerMarker(status: status, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              prayer.label,
              style: TextStyle(
                fontSize: 15.5,
                fontStyle:
                    prayer.isObligatory ? FontStyle.normal : FontStyle.italic,
                color: status == PrayerStatus.missed
                    ? const Color(0xFFB06B61)
                    : GardenColors.ink,
              ),
            ),
          ),
          if (prayer.isObligatory && time != null)
            Text(_time.format(time),
                style: const TextStyle(
                    color: GardenColors.muted, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _gratitudeProse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in _gratitude)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF5F5636),
              ),
            ),
          ),
      ],
    );
  }

  Widget _reflectionBlock() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBE4E0),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Text(
        entry.reflection.trim(),
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Color(0xFF7C352D),
        ),
      ),
    );
  }
}
