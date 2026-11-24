import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../../application/settings.dart';
import '../../domain/qibla.dart';
import '../../app/theme.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});
  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}
class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  Position? position;
  bool loading = false;
  String? error;
  Future<void> locate() async {
    setState(() { loading = true; error = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Включите геолокацию');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw StateError('Разрешите геолокацию в настройках');
      }
      final result = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 20)));
      if (mounted) setState(() => position = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final city = ref.watch(settingsProvider.select((s) => s.city));
    final bearing = Qibla.bearing(position?.latitude ?? city.latitude, position?.longitude ?? city.longitude);
    final mobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Направление Киблы', style: Theme.of(context).textTheme.headlineSmall),
      Text(position == null ? city.name : 'Координаты GPS'),
      const SizedBox(height: 20),
      if (mobile) StreamBuilder<CompassEvent>(stream: FlutterCompass.events, builder: (context, snapshot) {
        final raw = snapshot.data?.heading;
        return _Dial(bearing: bearing, heading: raw != null && raw.isFinite ? raw : null);
      }) else _Dial(bearing: bearing),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: loading ? null : locate, icon: const Icon(Icons.my_location), label: Text(loading ? 'Определение…' : 'Использовать GPS')),
      if (position != null) TextButton(onPressed: loading ? null : () => setState(() => position = null), child: const Text('Использовать город')),
      if (error != null) Text(error!),
    ]);
  }
}
class _Dial extends StatelessWidget {
  const _Dial({required this.bearing, this.heading});
  final double bearing;
  final double? heading;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: MihrabTokens.emerald, borderRadius: BorderRadius.circular(24)),
    child: Column(children: [
      Text('${bearing.toStringAsFixed(1)}°', style: const TextStyle(color: MihrabTokens.gold, fontSize: 36)),
      const SizedBox(height: 16),
      AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _CompassPainter(bearing, heading))),
      Text(heading == null ? 'Статический азимут • датчик недоступен' : 'Ориентировочное направление по датчику', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
    ]),
  );
}
class _CompassPainter extends CustomPainter {
  _CompassPainter(this.bearing, this.heading);
  final double bearing;
  final double? heading;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.shortestSide / 2 - 12;
    final paint = Paint()..color = MihrabTokens.gold..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(center, radius, paint);
    for (var i = 0; i < 360; i += 10) {
      final a = (i - (heading ?? 0)) * math.pi / 180;
      final v = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(center + v * radius, center + v * (radius - (i % 30 == 0 ? 10 : 5)), paint);
    }
    for (final e in {0:'N',90:'E',180:'S',270:'W'}.entries) {
      final a = (e.key - (heading ?? 0)) * math.pi / 180;
      final t = TextPainter(text: TextSpan(text: e.value, style: const TextStyle(color: Colors.white, fontSize: 14)), textDirection: TextDirection.ltr)..layout();
      final p = center + Offset(math.sin(a), -math.cos(a)) * (radius - 25);
      t.paint(canvas, p - Offset(t.width/2, t.height/2));
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((heading == null ? bearing : Qibla.relative(bearing, heading!)) * math.pi / 180);
    canvas.drawPath(Path()..moveTo(0,-radius+40)..lineTo(-14,20)..lineTo(0,8)..lineTo(14,20)..close(), Paint()..color = MihrabTokens.gold);
    canvas.restore();
  }
  @override
  bool shouldRepaint(_CompassPainter oldDelegate) => oldDelegate.bearing != bearing || oldDelegate.heading != heading;
}
