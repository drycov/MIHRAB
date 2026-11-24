import 'dart:ui';
import '../domain/prayer_schedule.dart';
import '../domain/reminders.dart';
import 'mihrab_strings.dart';

String resolveReminderLanguage(String? saved, Iterable<Locale> locales) {
  const supported = ['ru', 'kk', 'ar', 'en'];
  if (supported.contains(saved)) return saved!;
  for (final locale in locales) {
    if (supported.contains(locale.languageCode)) return locale.languageCode;
  }
  return 'ru';
}

class ReminderStrings {
  const ReminderStrings(this.language);
  final String language;
  String _pick(String ru, String kk, String ar, String en) =>
      switch (language) {
        'kk' => kk,
        'ar' => ar,
        'en' => en,
        _ => ru,
      };
  String prayer(PrayerKind kind) => translateMihrab(language, kind.label);
  String get suhoor => _pick('Сухур', 'Сәресі', 'السحور', 'Suhoor');
  String get iftar => _pick('Ифтар', 'Ауызашар', 'الإفطار', 'Iftar');
  String get preview => _pick(
    'Проверка звукового профиля',
    'Дыбыс профилін тексеру',
    'اختبار إعداد الصوت',
    'Sound profile test',
  );
  String get prayerStart => _pick(
    'Наступило время намаза',
    'Намаз уақыты келді',
    'حان وقت الصلاة',
    'It is time for prayer',
  );
  String title(PrayerReminder item) =>
      item.ramadan
          ? (item.kind == PrayerKind.fajr ? suhoor : iftar)
          : prayer(item.kind);
  String body(PrayerReminder item) {
    final n = item.minutesBefore;
    if (!item.ramadan)
      return n == 0
          ? prayerStart
          : _pick(
            'До намаза $n мин.',
            'Намазға $n мин. қалды',
            'بقي على الصلاة $n د',
            'Prayer in $n min',
          );
    if (item.kind == PrayerKind.fajr)
      return n == 0
          ? _pick(
            'Время окончания сухура',
            'Сәресі аяқталды',
            'حان وقت انتهاء السحور',
            'Suhoor has ended',
          )
          : _pick(
            'До окончания сухура $n мин.',
            'Сәресі аяқталуына $n мин. қалды',
            'بقي على انتهاء السحور $n د',
            'Suhoor ends in $n min',
          );
    return n == 0
        ? _pick(
          'Время ифтара',
          'Ауызашар уақыты',
          'حان وقت الإفطار',
          'It is time for iftar',
        )
        : _pick(
          'До ифтара $n мин.',
          'Ауызашарға $n мин. қалды',
          'بقي على الإفطار $n د',
          'Iftar in $n min',
        );
  }
}
