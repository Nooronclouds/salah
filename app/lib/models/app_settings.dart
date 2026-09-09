import 'package:salah/models/prayer.dart';

/// Prayer-time calculation method (a curated subset of the adhan library's).
enum CalcMethodOption {
  karachi,
  muslimWorldLeague,
  egyptian,
  ummAlQura,
  dubai,
  qatar,
  kuwait,
  singapore,
  northAmerica;

  String get label => switch (this) {
        CalcMethodOption.karachi => 'Karachi',
        CalcMethodOption.muslimWorldLeague => 'Muslim World League',
        CalcMethodOption.egyptian => 'Egyptian',
        CalcMethodOption.ummAlQura => 'Umm al-Qura',
        CalcMethodOption.dubai => 'Dubai',
        CalcMethodOption.qatar => 'Qatar',
        CalcMethodOption.kuwait => 'Kuwait',
        CalcMethodOption.singapore => 'Singapore',
        CalcMethodOption.northAmerica => 'North America',
      };
}

/// School determining Asr timing.
enum MadhabOption {
  hanafi,
  shafi;

  String get label => switch (this) {
        MadhabOption.hanafi => 'Hanafi',
        MadhabOption.shafi => 'Shafi',
      };
}

/// Where the day's page is saved at end of day.
enum ExportTarget {
  pngGallery,
  pdfDrive;

  String get label => switch (this) {
        ExportTarget.pngGallery => 'PNG → Gallery',
        ExportTarget.pdfDrive => 'PDF → Drive',
      };
}

/// All app + call configuration. Immutable — mutate via [copyWith].
class AppSettings {
  const AppSettings({
    this.phoneNumber = '',
    this.locationName = 'Hassan',
    this.latitude = 13.0073,
    this.longitude = 76.0962,
    this.method = CalcMethodOption.karachi,
    this.madhab = MadhabOption.hanafi,
    this.callPrayers = const {
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    },
    this.adhanChoice = 6,
    this.fajrSpeed = 1.5,
    this.introVoice = 'Christopher',
    this.exportTarget = ExportTarget.pngGallery,
    this.reminderHour = 21,
    this.reminderMinute = 30,
    this.timezone = 'Asia/Kolkata',
    this.callsEnabled = false,
    this.backendUrl = '',
    this.backendToken = '',
  });

  final String phoneNumber;
  final String locationName;
  final double latitude;
  final double longitude;
  final CalcMethodOption method;
  final MadhabOption madhab;
  final Set<Prayer> callPrayers;
  final int adhanChoice; // 1..14
  final double fajrSpeed; // 1.3 / 1.4 / 1.5
  final String introVoice;
  final ExportTarget exportTarget;
  final int reminderHour;
  final int reminderMinute;
  final String timezone;
  final bool callsEnabled;
  final String backendUrl;
  final String backendToken;

  AppSettings copyWith({
    String? phoneNumber,
    String? locationName,
    double? latitude,
    double? longitude,
    CalcMethodOption? method,
    MadhabOption? madhab,
    Set<Prayer>? callPrayers,
    int? adhanChoice,
    double? fajrSpeed,
    String? introVoice,
    ExportTarget? exportTarget,
    int? reminderHour,
    int? reminderMinute,
    String? timezone,
    bool? callsEnabled,
    String? backendUrl,
    String? backendToken,
  }) {
    return AppSettings(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      callPrayers: callPrayers ?? this.callPrayers,
      adhanChoice: adhanChoice ?? this.adhanChoice,
      fajrSpeed: fajrSpeed ?? this.fajrSpeed,
      introVoice: introVoice ?? this.introVoice,
      exportTarget: exportTarget ?? this.exportTarget,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      timezone: timezone ?? this.timezone,
      callsEnabled: callsEnabled ?? this.callsEnabled,
      backendUrl: backendUrl ?? this.backendUrl,
      backendToken: backendToken ?? this.backendToken,
    );
  }

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'method': method.name,
        'madhab': madhab.name,
        'callPrayers': callPrayers.map((p) => p.name).toList(),
        'adhanChoice': adhanChoice,
        'fajrSpeed': fajrSpeed,
        'introVoice': introVoice,
        'exportTarget': exportTarget.name,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'timezone': timezone,
        'callsEnabled': callsEnabled,
        'backendUrl': backendUrl,
        'backendToken': backendToken,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const defaults = AppSettings();
    return AppSettings(
      phoneNumber: (json['phoneNumber'] as String?) ?? defaults.phoneNumber,
      locationName: (json['locationName'] as String?) ?? defaults.locationName,
      latitude: (json['latitude'] as num?)?.toDouble() ?? defaults.latitude,
      longitude: (json['longitude'] as num?)?.toDouble() ?? defaults.longitude,
      method: _byName(CalcMethodOption.values, json['method']) ?? defaults.method,
      madhab: _byName(MadhabOption.values, json['madhab']) ?? defaults.madhab,
      callPrayers: _prayerSet(json['callPrayers']) ?? defaults.callPrayers,
      adhanChoice: (json['adhanChoice'] as int?) ?? defaults.adhanChoice,
      fajrSpeed: (json['fajrSpeed'] as num?)?.toDouble() ?? defaults.fajrSpeed,
      introVoice: (json['introVoice'] as String?) ?? defaults.introVoice,
      exportTarget:
          _byName(ExportTarget.values, json['exportTarget']) ?? defaults.exportTarget,
      reminderHour: (json['reminderHour'] as int?) ?? defaults.reminderHour,
      reminderMinute: (json['reminderMinute'] as int?) ?? defaults.reminderMinute,
      timezone: (json['timezone'] as String?) ?? defaults.timezone,
      callsEnabled: (json['callsEnabled'] as bool?) ?? defaults.callsEnabled,
      backendUrl: (json['backendUrl'] as String?) ?? defaults.backendUrl,
      backendToken: (json['backendToken'] as String?) ?? defaults.backendToken,
    );
  }

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static Set<Prayer>? _prayerSet(Object? raw) {
    if (raw is! List) return null;
    return {
      for (final name in raw)
        for (final prayer in Prayer.values)
          if (prayer.name == name) prayer,
    };
  }
}
