import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;

enum PrayerKind {
  fajr('Фаджр', 'الفجر'), sunrise('Восход', 'الشروق'),
  dhuhr('Зухр', 'الظهر'), asr('Аср', 'العصر'),
  maghrib('Магриб', 'المغرب'), isha('Иша', 'العشاء');
  const PrayerKind(this.label, this.arabic);
  final String label;
  final String arabic;
  bool get obligatory => this != sunrise;
}

class City {
  const City(this.name, this.latitude, this.longitude, this.zone);
  final String name;
  final double latitude, longitude;
  final String zone;
  static const all = [
    City('Усть-Каменогорск', 49.948, 82.628, 'Asia/Almaty'),
    City('Алматы', 43.238, 76.945, 'Asia/Almaty'),
    City('Астана', 51.169, 71.449, 'Asia/Almaty'),
    City('Шымкент', 42.315, 69.59, 'Asia/Almaty'),
    City('Актау', 43.65, 51.15, 'Asia/Aqtau'),
  ];
}

class PrayerSlot {
  const PrayerSlot(this.kind, this.time);
  final PrayerKind kind;
  final tz.TZDateTime time;
}

class PrayerSchedule {
  static List<PrayerSlot> forDay(City city, DateTime day, {bool hanafi = true}) {
    final zone = tz.getLocation(city.zone);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = hanafi ? Madhab.hanafi : Madhab.shafi;
    final times = PrayerTimes.utc(
      Coordinates(city.latitude, city.longitude),
      DateComponents(day.year, day.month, day.day), params,
    );
    final raw = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.maghrib, times.isha];
    return List.generate(raw.length, (i) => PrayerSlot(
      PrayerKind.values[i], tz.TZDateTime.from(raw[i], zone),
    ));
  }

  static PrayerSlot next(City city, DateTime instant, {bool hanafi = true}) {
    final now = tz.TZDateTime.from(instant, tz.getLocation(city.zone));
    final today = forDay(city, now, hanafi: hanafi);
    for (final slot in today) {
      if (slot.kind.obligatory && slot.time.isAfter(now)) return slot;
    }
    return forDay(city, DateTime(now.year, now.month, now.day + 1), hanafi: hanafi).first;
  }
}
