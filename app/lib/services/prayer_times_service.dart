import 'package:adhan/adhan.dart' hide Prayer;
import 'package:salah/models/prayer.dart';

/// Computes prayer times offline, mirroring the call backend's settings
/// (Hassan, Karachi method, Hanafi madhab). These will later come from Settings.
class PrayerTimesService {
  const PrayerTimesService({
    this.latitude = 13.0073,
    this.longitude = 76.0962,
  });

  final double latitude;
  final double longitude;

  /// Returns the clock time for each timed prayer on [date]. Tahajjud has no
  /// fixed time, so it is absent from the map.
  Map<Prayer, DateTime> timesFor(DateTime date) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.hanafi;
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(date),
      params,
    );

    return {
      Prayer.fajr: prayerTimes.fajr,
      Prayer.dhuhr: prayerTimes.dhuhr,
      Prayer.asr: prayerTimes.asr,
      Prayer.maghrib: prayerTimes.maghrib,
      Prayer.isha: prayerTimes.isha,
      // Ishraq begins shortly after sunrise; sunrise is a close enough anchor.
      Prayer.ishraq: prayerTimes.sunrise,
    };
  }
}
