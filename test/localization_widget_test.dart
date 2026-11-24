import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/l10n/mihrab_strings.dart';

void main() {
  for (final locale in supportedMihrabLocales) {
    testWidgets('Material localization resolves ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: supportedMihrabLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Text(
                  '${Localizations.localeOf(context).languageCode}:${Directionality.of(context).name}',
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final direction = locale.languageCode == 'ar' ? 'rtl' : 'ltr';
      expect(find.text('${locale.languageCode}:$direction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
