import 'package:flutter/material.dart';
import 'package:salah/models/app_settings.dart';
import 'package:salah/models/journal_entry.dart';
import 'package:salah/models/prayer.dart';
import 'package:salah/services/export_service.dart';
import 'package:salah/services/journal_store.dart';
import 'package:salah/services/prayer_times_service.dart';
import 'package:salah/services/settings_store.dart';
import 'package:salah/theme.dart';
import 'package:salah/widgets/keepsake_page.dart';

/// Shows the day's keepsake page and saves it (PNG to gallery / PDF to Drive).
class ExportPreviewScreen extends StatefulWidget {
  const ExportPreviewScreen({super.key, required this.date});

  final DateTime date;

  @override
  State<ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<ExportPreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final ExportService _export = ExportService();

  AppSettings _settings = const AppSettings();
  JournalEntry _entry = JournalEntry.empty('');
  Map<Prayer, DateTime> _times = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await SettingsStore().load();
    final entry = await JournalStore().load(JournalStore.keyFor(widget.date));
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _entry = entry;
      _times = PrayerTimesService.fromSettings(settings).timesFor(widget.date);
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await _export.capturePng(_boundaryKey);
      if (png == null) {
        _notify(messenger, 'Could not render the page — please try again.');
        return;
      }
      final message = await _export.save(
        png: png,
        target: _settings.exportTarget,
        dateKey: JournalStore.keyFor(widget.date),
      );
      _notify(messenger, message);
    } on Exception catch (_) {
      _notify(messenger, 'Saving failed. Please check permissions and retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notify(ScaffoldMessengerState messenger, String text) {
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GardenColors.parchment,
        elevation: 0,
        foregroundColor: GardenColors.fernDeep,
        title: Text("Today's page",
            style: Theme.of(context).textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: GardenColors.fern))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: SizedBox(
                            width: 420,
                            child: KeepsakePage(
                              date: widget.date,
                              entry: _entry,
                              times: _times,
                              locationName: _settings.locationName,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _saveBar(),
              ],
            ),
    );
  }

  Widget _saveBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GardenColors.fern,
              foregroundColor: GardenColors.parchment,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Saving…' : 'Save today’s page  ·  ${_settings.exportTarget.label}',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
