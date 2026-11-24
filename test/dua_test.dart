import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/dua.dart';

void main() {
  test('catalog contains distinct identifiers and sources', () {
    expect(duas.map((d) => d.id).toSet().length, duas.length);
    for (final d in duas) {
      expect(d.arabic, isNotEmpty);
      expect(d.repetitions, greaterThan(0));
      expect(Uri.parse(d.url).scheme, 'https');
    }
  });
  test('post prayer sequence totals one hundred', () {
    expect(
      duas
          .where((d) => d.category == DuaCategory.afterPrayer)
          .fold<int>(0, (n, d) => n + d.repetitions),
      100,
    );
  });
}
