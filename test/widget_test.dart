import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mihrab/app/app.dart';
import 'package:mihrab/application/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MihrabApp builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
        ],
        child: const MihrabApp(),
      ),
    );

    // Smoke test: app builds and shows the main shell
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('MIHRAB'), findsOneWidget);
  });
}