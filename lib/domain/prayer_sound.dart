import 'prayer_schedule.dart';

enum PrayerSound {
  system('Системный звук'),
  vibration('Только вибрация'),
  silent('Без звука'),
  adhan('Локальный азан');

  const PrayerSound(this.label);
  final String label;
  static PrayerSound parse(Object? value) =>
      values.firstWhere((p) => p.name == value, orElse: () => system);
}

abstract final class PrayerSoundChannels {
  static String id(PrayerKind kind, PrayerSound sound, {bool early = false}) =>
      'mihrab_${kind.name}_${early ? "early" : "start"}_${sound.name}_v1';
  static String label(
    PrayerKind kind,
    PrayerSound sound, {
    bool early = false,
  }) => '${kind.label} · ${early ? "Напоминание" : "Начало"} · ${sound.label}';
}
