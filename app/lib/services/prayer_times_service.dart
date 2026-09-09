import 'package:adhan/adhan.dart' hide Prayer;
import 'package:salah/models/app_settings.dart';
import 'package:salah/models/prayer.dart';

/// Computes prayer times offline, from the user's settings (location, method,
/// madhab). Mirrors the call backend so the app and the call agree.
class PrayerTimesService {
  const PrayerTimesService({
    this.latitude = 13.0073,
    this.longitude = 76.0962,
    this.method = CalcMethodOption.karachi,
    this.madhab = MadhabOption.hanafi,
  });

  factory PrayerTimesService.fromSettings(AppSettings settings) {
    return PrayerTimesService(
      latitude: settings.latitude,
      longitude: settings.longitude,
      method: settings.method,
      madhab: settings.madhab,
    );
  }

  final double latitude;
  final double longitude;
  final CalcMethodOption method;
  final MadhabOption madhab;

  /// Returns the clock time for each timed prayer on [date]. Tahajjud has no
  /// fixed time, so it is absent from the map.
  Map<Prayer, DateTime> timesFor(DateTime date) {
    final coordinates = Coordinates(latitude, longitude);
    final params = _method().getParameters()..madhab = _madhab();
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

  CalculationMethod _method() => switch (method) {
        CalcMethodOption.karachi => CalculationMethod.karachi,
        CalcMethodOption.muslimWorldLeague => CalculationMethod.muslim_world_league,
        CalcMethodOption.egyptian => CalculationMethod.egyptian,
        CalcMethodOption.ummAlQura => CalculationMethod.umm_al_qura,
        CalcMethodOption.dubai => CalculationMethod.dubai,
        CalcMethodOption.qatar => CalculationMethod.qatar,
        CalcMethodOption.kuwait => CalculationMethod.kuwait,
        CalcMethodOption.singapore => CalculationMethod.singapore,
        CalcMethodOption.northAmerica => CalculationMethod.north_america,
      };

  Madhab _madhab() => switch (madhab) {
        MadhabOption.hanafi => Madhab.hanafi,
        MadhabOption.shafi => Madhab.shafi,
      };
}
