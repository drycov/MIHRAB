import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mihrab/app/app.dart';
import 'package:mihrab/application/settings.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  testWidgets('Settings and reminder dropdowns have Material ancestors', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true, 'app_locale_v1': 'ru'});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const MihrabApp(),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final city = find.byType(DropdownButton<int>);
    expect(city, findsOneWidget);
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Алматы').last);
    await tester.pumpAndSettle();
    expect(preferences.getInt('city'), 1);
    final reminders = find.text('Уведомления');
    await tester.scrollUntilVisible(reminders, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(reminders);
    await tester.pumpAndSettle();
    final lead = find.byType(DropdownButton<int>);
    await tester.scrollUntilVisible(lead, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(lead);
    await tester.tap(lead);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('За 15 мин.').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }, variant: const TargetPlatformVariant({TargetPlatform.windows}));
}
