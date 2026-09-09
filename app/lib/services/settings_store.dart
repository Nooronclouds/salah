import 'dart:convert';

import 'package:salah/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists [AppSettings] locally. Local-first: nothing leaves the device.
class SettingsStore {
  static const String _key = 'app_settings';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
