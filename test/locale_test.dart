import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/l10n/mihrab_strings.dart';
import 'package:mihrab/application/locale.dart';
import 'package:mihrab/application/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('translations and fallback', () {
    expect(translateMihrab('kk', 'Город'), 'Қала');
    expect(translateMihrab('ar', 'Намаз'), 'الصلاة');
    expect(translateMihrab('en', 'Календарь'), 'Calendar');
    expect(translateMihrab('ru', 'Календарь'), 'Календарь');
    expect(translateMihrab('en', 'unknown'), 'unknown');
  });
  test('locale preference persists and system mode clears it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    expect(c.read(localeProvider), isNull);
    await c.read(localeProvider.notifier).change('kk');
    expect(c.read(localeProvider)?.languageCode, 'kk');
    final restored = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restored.dispose);
    expect(restored.read(localeProvider)?.languageCode, 'kk');
    await c.read(localeProvider.notifier).change(null);
    expect(prefs.containsKey(LocaleController.key), isFalse);
  });
}
