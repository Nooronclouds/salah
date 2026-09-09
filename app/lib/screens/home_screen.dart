import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salah/models/journal_entry.dart';
import 'package:salah/models/prayer.dart';
import 'package:salah/services/journal_store.dart';
import 'package:salah/services/photo_service.dart';
import 'package:salah/services/prayer_times_service.dart';
import 'package:salah/services/settings_store.dart';
import 'package:salah/screens/export_preview_screen.dart';
import 'package:salah/screens/settings_screen.dart';
import 'package:salah/theme.dart';
import 'package:salah/widgets/garden.dart';

/// The journal home page — the app opens here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final JournalStore _store = JournalStore();
  final SettingsStore _settingsStore = SettingsStore();
  final PhotoService _photos = PhotoService();
  final DateFormat _time = DateFormat('HH:mm');

  final DateTime _date = DateTime.now();
  Map<Prayer, DateTime> _times = {};
  late final TextEditingController _reflection = TextEditingController();
  final List<TextEditingController> _gratitude = [];

  Timer? _debounce;
  JournalEntry _entry = JournalEntry.empty(JournalStore.keyFor(DateTime.now()));
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _reflection.dispose();
    for (final controller in _gratitude) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _settingsStore.load();
    final entry = await _store.load(JournalStore.keyFor(_date));
    if (!mounted) return;
    setState(() {
      _times = PrayerTimesService.fromSettings(settings).timesFor(_date);
      _entry = entry;
      _reflection.text = entry.reflection;
      _gratitude
        ..clear()
        ..addAll(entry.gratitude.map((t) => TextEditingController(text: t)));
      if (_gratitude.isEmpty) _gratitude.add(TextEditingController());
      _loading = false;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    // Settings may have changed location/method/madhab — recompute times.
    final settings = await _settingsStore.load();
    if (!mounted) return;
    setState(() {
      _times = PrayerTimesService.fromSettings(settings).timesFor(_date);
    });
  }

  void _persistSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _store.save(_entry);
    });
  }

  void _cyclePrayer(Prayer prayer) {
    final next = switch (_entry.statusOf(prayer)) {
      PrayerStatus.pending => PrayerStatus.done,
      PrayerStatus.done => PrayerStatus.pending,
      PrayerStatus.missed => PrayerStatus.pending,
    };
    _setStatus(prayer, next);
  }

  void _markMissed(Prayer prayer) {
    final next = _entry.statusOf(prayer) == PrayerStatus.missed
        ? PrayerStatus.pending
        : PrayerStatus.missed;
    _setStatus(prayer, next);
  }

  void _setStatus(Prayer prayer, PrayerStatus status) {
    setState(() {
      _entry = _entry.copyWith(
        statuses: {..._entry.statuses, prayer: status},
      );
    });
    _persistSoon();
  }

  void _onGratitudeChanged() {
    _entry = _entry.copyWith(
      gratitude: _gratitude
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );
    _persistSoon();
  }

  void _addGratitudeLine() {
    setState(() => _gratitude.add(TextEditingController()));
  }

  void _onReflectionChanged(String value) {
    _entry = _entry.copyWith(reflection: value);
    _persistSoon();
  }

  Future<void> _addPhoto() async {
    final path = await _photos.pickFromGallery();
    if (path == null || !mounted) return;
    setState(() {
      _entry = _entry.copyWith(photoPaths: [..._entry.photoPaths, path]);
    });
    _store.save(_entry);
  }

  void _removePhoto(String path) {
    setState(() {
      _entry = _entry.copyWith(
        photoPaths: _entry.photoPaths.where((p) => p != path).toList(),
      );
    });
    _store.save(_entry);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: GardenColors.fern)),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            _header(context),
            const SectionHeader('Prayers'),
            _prayersCard(),
            const SectionHeader('Grateful for today'),
            _gratitudeCard(),
            const SectionHeader('Reflection'),
            _reflectionCard(),
            const SectionHeader('Photos'),
            _photosCard(),
            const SizedBox(height: 22),
            _saveDayButton(),
          ],
        ),
      ),
    );
  }

  Widget _saveDayButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ExportPreviewScreen(date: _date),
            ),
          );
        },
        icon: const Icon(Icons.eco_outlined, color: GardenColors.fern, size: 18),
        label: const Text('save today’s page',
            style: TextStyle(color: GardenColors.fern)),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const Align(alignment: Alignment.topCenter, child: Garland()),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.menu, color: GardenColors.fern),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Salah & Gratitude',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(
          DateFormat('EEEE · dd MMMM yyyy').format(_date),
          style: const TextStyle(color: GardenColors.muted, fontSize: 13.5),
        ),
      ],
    );
  }

  Widget _prayersCard() {
    return GardenCard(
      child: Column(
        children: [
          for (final prayer in Prayer.obligatory) _prayerRow(prayer),
          const SprigDivider(),
          for (final prayer in Prayer.optional) _prayerRow(prayer),
        ],
      ),
    );
  }

  Widget _prayerRow(Prayer prayer) {
    final time = _times[prayer];
    final status = _entry.statusOf(prayer);
    final done = status == PrayerStatus.done;
    final missed = status == PrayerStatus.missed;
    return InkWell(
      onTap: () => _cyclePrayer(prayer),
      onLongPress: () => _markMissed(prayer),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            PrayerMarker(status: status),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                prayer.label,
                style: TextStyle(
                  fontSize: 16.5,
                  fontStyle: prayer.isObligatory ? FontStyle.normal : FontStyle.italic,
                  color: missed
                      ? const Color(0xFFB06B61)
                      : done
                          ? GardenColors.fernDeep
                          : GardenColors.ink,
                ),
              ),
            ),
            Text(
              prayer.isObligatory && time != null
                  ? _time.format(time)
                  : 'optional',
              style: const TextStyle(color: GardenColors.muted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gratitudeCard() {
    return GardenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _gratitude.length; i++)
            _journalLine(_gratitude[i], onChanged: (_) => _onGratitudeChanged()),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addGratitudeLine,
              icon: const Icon(Icons.add_circle_outline,
                  color: GardenColors.fern, size: 18),
              label: const Text('add a gratitude',
                  style: TextStyle(color: GardenColors.fern)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reflectionCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6BDB6), GardenColors.melon],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: TextField(
        controller: _reflection,
        onChanged: _onReflectionChanged,
        minLines: 2,
        maxLines: 6,
        cursorColor: const Color(0xFF7C352D),
        style: const TextStyle(color: Color(0xFF7C352D), height: 1.6),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'if a prayer slipped, or anything on your heart…',
          hintStyle: TextStyle(color: Color(0x887C352D), fontSize: 14),
        ),
      ),
    );
  }

  Widget _photosCard() {
    return GardenCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final path in _entry.photoPaths) _photoTile(path),
            _addPhotoTile(),
          ],
        ),
      ),
    );
  }

  Widget _photoTile(String path) {
    return Stack(
      children: [
        PhotoThumb(path: path),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: () => _removePhoto(path),
            icon: const CircleAvatar(
              radius: 11,
              backgroundColor: GardenColors.melon,
              child: Icon(Icons.close, size: 13, color: Color(0xFF7C352D)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addPhotoTile() {
    return InkWell(
      onTap: _addPhoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GardenColors.pistachio, width: 1.4),
        ),
        child: const Icon(Icons.add_a_photo_outlined,
            color: GardenColors.fern, size: 22),
      ),
    );
  }

  Widget _journalLine(
    TextEditingController controller, {
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: GardenColors.fern,
        style: const TextStyle(color: Color(0xFF8A7752), fontStyle: FontStyle.italic),
        decoration: const InputDecoration(
          isDense: true,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: GardenColors.line),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: GardenColors.line),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: GardenColors.pistachio),
          ),
        ),
      ),
    );
  }
}
