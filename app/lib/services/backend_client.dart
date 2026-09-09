import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:salah/models/app_settings.dart';

/// Raised when the call service can't be reached or rejects a request. The
/// message is safe to show to the user.
class BackendException implements Exception {
  const BackendException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the Salah call-service backend: pushes settings and triggers a
/// test call. The backend holds the Twilio credentials; the app only sends
/// call preferences plus the shared API token.
class BackendClient {
  const BackendClient({this.timeout = const Duration(seconds: 12)});

  final Duration timeout;

  Future<String> pushConfig(AppSettings settings) async {
    return _post('/config', _configPayload(settings), settings);
  }

  Future<String> sendTestCall(AppSettings settings) async {
    return _post('/test-call', const {}, settings);
  }

  Map<String, dynamic> _configPayload(AppSettings s) => {
        'enabled': s.callsEnabled,
        'to_number': s.phoneNumber,
        'latitude': s.latitude,
        'longitude': s.longitude,
        'timezone': s.timezone,
        'method': s.method.name,
        'madhab': s.madhab.name,
        'call_prayers': s.callPrayers.map((p) => p.name).toList(),
        'adhan_choice': s.adhanChoice,
        'fajr_speed': s.fajrSpeed,
      };

  Future<String> _post(
    String path,
    Map<String, dynamic> body,
    AppSettings settings,
  ) async {
    final base = settings.backendUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const BackendException('Set the call service URL first.');
    }
    final uri = Uri.tryParse('$base$path');
    if (uri == null || !uri.hasScheme) {
      throw const BackendException('That call service URL looks invalid.');
    }
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${settings.backendToken}',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _handle(response);
    } on BackendException {
      rethrow;
    } on Exception {
      throw const BackendException('Could not reach the call service.');
    }
  }

  String _handle(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return 'Done.';
      case 401:
        throw const BackendException('Token rejected — check the API token.');
      case 400:
        throw const BackendException('Missing details (is your number set?).');
      default:
        throw BackendException('Call service error (${response.statusCode}).');
    }
  }
}
