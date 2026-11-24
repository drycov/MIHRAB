import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/shared/format.dart';

void main() {
  test('countdown clamps negative duration', () {
    expect(formatRemaining(const Duration(seconds: -2)), '00:00:00');
  });
  test('countdown rounds up partial seconds', () {
    expect(formatRemaining(const Duration(milliseconds: 1001)), '00:00:02');
  });
  test('countdown supports more than one hour', () {
    expect(
      formatRemaining(const Duration(hours: 2, minutes: 3, seconds: 4)),
      '02:03:04',
    );
  });
}
