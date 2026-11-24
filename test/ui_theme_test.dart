import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/app/theme.dart';
import 'package:mihrab/shared/islamic_ornaments.dart';

void main() {
  for(final brightness in Brightness.values){
    test('primary CTA follows design guide: $brightness',(){
      final theme=MihrabTheme.build(brightness);
      final dark=brightness==Brightness.dark;
      final style=theme.filledButtonTheme.style!;
      expect(style.backgroundColor!.resolve(<WidgetState>{}),dark?MihrabTokens.gold:MihrabTokens.emerald);
      expect(style.foregroundColor!.resolve(<WidgetState>{}),dark?MihrabTokens.background:MihrabTokens.cream);
    });
    testWidgets('IslamicCard supplies a local Material for interactive tiles: $brightness', (tester) async {
      var tapped = false;
      var enabled = false;
      await tester.pumpWidget(MaterialApp(
        theme: MihrabTheme.build(brightness),
        home: Scaffold(body: ListView(children: [
          for (final highlighted in [false, true])
            IslamicCard(
              highlighted: highlighted,
              padding: EdgeInsets.zero,
              child: Column(children: [
                ListTile(title: Text('Open $highlighted'), onTap: () => tapped = true),
                SwitchListTile(title: Text('Switch $highlighted'), value: enabled, onChanged: (value) => enabled = value),
              ]),
            ),
        ])),
      ));
      for (final element in find.byType(ListTile).evaluate()) {
        final material = element.findAncestorWidgetOfExactType<Material>();
        expect(material?.type, MaterialType.transparency);
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Open false'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      await tester.tap(find.text('Switch false'));
      await tester.pumpAndSettle();
      expect(enabled, isTrue);
      expect(tester.takeException(), isNull);
    });
    testWidgets('shared UI components render: $brightness',(tester)async{
      await tester.pumpWidget(MaterialApp(theme:MihrabTheme.build(brightness),home:Scaffold(body:ListView(children:const [
        IslamicSectionTitle('Section'),IslamicCard(child:Text('Card')),IslamicDivider(),MihrabFrame(child:Text('Hero')),
      ]))));
      expect(find.text('Card'),findsOneWidget);
      expect(find.text('Hero'),findsOneWidget);
      expect(tester.takeException(),isNull);
    });
  }
}
