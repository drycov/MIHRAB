import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/qibla.dart';
void main() {
  test('Kazakhstan bearing points southwest', () {
    expect(Qibla.bearing(49.948,82.628), inInclusiveRange(230,270));
  });
  test('wrap across north', () {
    expect(Qibla.relative(5,355),10);
    expect(Qibla.relative(355,5),-10);
  });
}
