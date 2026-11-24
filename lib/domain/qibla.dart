import 'dart:math' as m;
abstract final class Qibla {
  static double rad(double v) => v * m.pi / 180;
  static double normalize(double v) => (v % 360 + 360) % 360;
  static double bearing(double lat, double lon) {
    final p = rad(lat), q = rad(21.422487), d = rad(39.826206 - lon);
    return normalize(m.atan2(m.sin(d)*m.cos(q), m.cos(p)*m.sin(q)-m.sin(p)*m.cos(q)*m.cos(d))*180/m.pi);
  }
  static double relative(double target, double heading) => (target-heading+540)%360-180;
}
