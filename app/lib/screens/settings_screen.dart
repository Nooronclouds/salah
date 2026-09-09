import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salah/models/app_settings.dart';
import 'package:salah/models/prayer.dart';
import 'package:salah/services/settings_store.dart';
import 'package:salah/theme.dart';
import 'package:salah/widgets/garden.dart';
import 'package:salah/widgets/settings_editors.dart';

/// The settings screen — all prayer/call and journal configuration lives here.
/// Reached from the journal's menu button.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsStore _store = SettingsStore();
  AppSettings _settings = const AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  void _update(AppSettings next) {
    setState(() => _settings = next);
    _store.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GardenColors.parchment,
        elevation: 0,
        foregroundColor: GardenColors.fernDeep,
        title: Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: GardenColors.fern))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
              children: [
                const SectionHeader('The call'),
                _callCard(),
                const SectionHeader('Journal'),
                _journalCard(),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'the call you won’t ignore',
                    style: TextStyle(
                      color: GardenColors.muted,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _callCard() {
    return GardenCard(
      child: Column(
        children: [
          SettingRow(
            label: 'Phone',
            value: _settings.phoneNumber.isEmpty ? 'not set' : _settings.phoneNumber,
            onTap: _editPhone,
          ),
          SettingRow(
            label: 'Location',
            value: _settings.locationName,
            onTap: _editLocation,
          ),
          SettingRow(
            label: 'Method',
            value: _settings.method.label,
            onTap: _editMethod,
          ),
          SettingRow(
            label: 'Madhab',
            value: _settings.madhab.label,
            onTap: _editMadhab,
          ),
          _callPrayersRow(),
          SettingRow(
            label: 'Adhan',
            value: '#${_settings.adhanChoice}',
            onTap: _editAdhan,
          ),
          SettingRow(
            label: 'Fajr adhan',
            value: '${_settings.fajrSpeed}×',
            onTap: _editFajrSpeed,
          ),
          SettingRow(
            label: 'Intro voice',
            value: _settings.introVoice,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _journalCard() {
    final time = TimeOfDay(
      hour: _settings.reminderHour,
      minute: _settings.reminderMinute,
    );
    return GardenCard(
      child: Column(
        children: [
          SettingRow(
            label: 'Save as',
            value: _settings.exportTarget.label,
            onTap: _editExport,
          ),
          SettingRow(
            label: 'Daily reminder',
            value: time.format(context),
            onTap: _editReminder,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _callPrayersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Call me for', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final prayer in Prayer.obligatory) _prayerChip(prayer),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF0EAD6)),
        ],
      ),
    );
  }

  Widget _prayerChip(Prayer prayer) {
    final selected = _settings.callPrayers.contains(prayer);
    return FilterChip(
      label: Text(prayer.label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: GardenColors.paper,
      selectedColor: GardenColors.pistachio,
      side: const BorderSide(color: GardenColors.pistachio),
      labelStyle: TextStyle(
        color: selected ? GardenColors.fernDeep : GardenColors.muted,
      ),
      onSelected: (on) {
        final next = {..._settings.callPrayers};
        if (on) {
          next.add(prayer);
        } else {
          next.remove(prayer);
        }
        _update(_settings.copyWith(callPrayers: next));
      },
    );
  }

  Future<void> _editPhone() async {
    final result = await editText(
      context,
      title: 'Phone number',
      initial: _settings.phoneNumber,
      hint: '+91…',
      keyboardType: TextInputType.phone,
      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
    );
    if (result != null) _update(_settings.copyWith(phoneNumber: result.trim()));
  }

  Future<void> _editLocation() async {
    final result = await editLocation(
      context,
      name: _settings.locationName,
      latitude: _settings.latitude,
      longitude: _settings.longitude,
    );
    if (result != null) {
      _update(_settings.copyWith(
        locationName: result.name,
        latitude: result.latitude,
        longitude: result.longitude,
      ));
    }
  }

  Future<void> _editMethod() async {
    final result = await chooseOne<CalcMethodOption>(
      context,
      title: 'Calculation method',
      options: CalcMethodOption.values,
      current: _settings.method,
      labelOf: (m) => m.label,
    );
    if (result != null) _update(_settings.copyWith(method: result));
  }

  Future<void> _editMadhab() async {
    final result = await chooseOne<MadhabOption>(
      context,
      title: 'Madhab (Asr timing)',
      options: MadhabOption.values,
      current: _settings.madhab,
      labelOf: (m) => m.label,
    );
    if (result != null) _update(_settings.copyWith(madhab: result));
  }

  Future<void> _editAdhan() async {
    final result = await chooseOne<int>(
      context,
      title: 'Adhan',
      options: List.generate(14, (i) => i + 1),
      current: _settings.adhanChoice,
      labelOf: (n) => 'Adhan #$n',
    );
    if (result != null) _update(_settings.copyWith(adhanChoice: result));
  }

  Future<void> _editFajrSpeed() async {
    final result = await chooseOne<double>(
      context,
      title: 'Fajr adhan speed',
      options: const [1.3, 1.4, 1.5],
      current: _settings.fajrSpeed,
      labelOf: (s) => '$s×',
    );
    if (result != null) _update(_settings.copyWith(fajrSpeed: result));
  }

  Future<void> _editExport() async {
    final result = await chooseOne<ExportTarget>(
      context,
      title: 'Save the day as',
      options: ExportTarget.values,
      current: _settings.exportTarget,
      labelOf: (t) => t.label,
    );
    if (result != null) _update(_settings.copyWith(exportTarget: result));
  }

  Future<void> _editReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.reminderHour,
        minute: _settings.reminderMinute,
      ),
    );
    if (picked != null) {
      _update(_settings.copyWith(
        reminderHour: picked.hour,
        reminderMinute: picked.minute,
      ));
    }
  }
}
