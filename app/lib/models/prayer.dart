/// The prayers a day can track: the five obligatory, plus two optional.
enum Prayer {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
  tahajjud,
  ishraq;

  /// Display label shown in the journal.
  String get label => switch (this) {
        Prayer.fajr => 'Fajr',
        Prayer.dhuhr => 'Dhuhr',
        Prayer.asr => 'Asr',
        Prayer.maghrib => 'Maghrib',
        Prayer.isha => 'Isha',
        Prayer.tahajjud => 'Tahajjud',
        Prayer.ishraq => 'Ishraq',
      };

  /// The five daily obligatory prayers.
  bool get isObligatory => switch (this) {
        Prayer.fajr ||
        Prayer.dhuhr ||
        Prayer.asr ||
        Prayer.maghrib ||
        Prayer.isha =>
          true,
        Prayer.tahajjud || Prayer.ishraq => false,
      };

  /// The prayers shown on the daily page, in order.
  static const List<Prayer> obligatory = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  static const List<Prayer> optional = [Prayer.tahajjud, Prayer.ishraq];
}

/// Where a prayer stands for a given day.
enum PrayerStatus {
  /// Not marked yet (a closed marker).
  pending,

  /// Prayed (a filled check).
  done,

  /// Its window passed unprayed (the honest "missed" marker).
  missed;
}
