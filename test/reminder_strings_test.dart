import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/l10n/reminder_strings.dart';
import 'package:mihrab/domain/prayer_schedule.dart';
void main(){
  test('manual locale overrides system',(){
    expect(resolveReminderLanguage('kk',[const Locale('en')]),'kk');
    expect(resolveReminderLanguage(null,[const Locale('de'),const Locale('ar')]),'ar');
    expect(resolveReminderLanguage(null,[const Locale('de')]),'ru');
  });
  test('prayer labels and reminder text',(){
    expect(const ReminderStrings('en').prayer(PrayerKind.fajr),'Fajr');
    expect(const ReminderStrings('ar').iftar,'الإفطار');
    expect(const ReminderStrings('kk').suhoor,'Сәресі');
    expect(const ReminderStrings('ru').prayerStart,'Наступило время намаза');
  });
}
