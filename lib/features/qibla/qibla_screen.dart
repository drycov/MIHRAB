import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../../application/settings.dart';
import '../../domain/qibla.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

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
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Включите геолокацию');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Разрешите геолокацию в настройках');
      }
      final result = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (mounted) setState(() => position = result);
    } catch (e) {
      if (mounted) setState(() => error = e is StateError ? e.message.toString() : 'Не удалось определить местоположение');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(settingsProvider.select((s) => s.city));
    final bearing = Qibla.bearing(
      position?.latitude ?? city.latitude,
      position?.longitude ?? city.longitude,
    );
    final mobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          context.tr('Кибла').toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 3.5,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr(position == null ? city.name : 'Координаты GPS'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const IslamicDivider(),
        if (mobile)
          StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              final raw = snapshot.data?.heading;
              return _Dial(
                bearing: bearing,
                heading: raw != null && raw.isFinite ? raw : null,
              );
            },
          )
        else
          _Dial(bearing: bearing),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: loading ? null : locate,
          icon: const Icon(Icons.my_location),
          label: Text(context.tr(loading ? 'Определение…' : 'Использовать GPS')),
          style: FilledButton.styleFrom(
            backgroundColor: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            foregroundColor:
                dark ? MihrabTokens.background : MihrabTokens.cream,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MihrabTokens.radius),
            ),
          ),
        ),
        if (position != null)
          TextButton(
            onPressed: loading ? null : () => setState(() => position = null),
            child: Text(context.tr('Использовать город')),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr(error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({required this.bearing, this.heading});
  final double bearing;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    return MihrabFrame(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        children: [
          const IslamicStar(size: 22, color: MihrabTokens.gold),
          const SizedBox(height: 10),
          Text(
            '${bearing.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: MihrabTokens.gold,
              fontSize: 40,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            context.tr('азимут Киблы'),
            style: TextStyle(
              color: MihrabTokens.goldSoft.withValues(alpha: 0.85),
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _CompassPainter(bearing, heading),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            heading == null
                ? context.tr('Статический азимут · датчик недоступен')
                : context.tr('Ориентировочное направление по датчику'),
            style: TextStyle(
              color: MihrabTokens.paper.withValues(alpha: 0.85),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.bearing, this.heading);
  final double bearing;
  final double? heading;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;

    final ring = Paint()
      ..color = MihrabTokens.gold.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final ringSoft = Paint()
      ..color = MihrabTokens.gold.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * 0.72, ringSoft);
    canvas.drawCircle(center, radius * 0.12, ring);

    final tick = Paint()
      ..color = MihrabTokens.gold.withValues(alpha: 0.75)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 360; i += 10) {
      final a = (i - (heading ?? 0)) * math.pi / 180;
      final v = Offset(math.sin(a), -math.cos(a));
      final major = i % 30 == 0;
      canvas.drawLine(
        center + v * radius,
        center + v * (radius - (major ? 12 : 6)),
        tick..strokeWidth = major ? 1.8 : 1,
      );
    }

    for (final e in {0: 'N', 90: 'E', 180: 'S', 270: 'W'}.entries) {
      final a = (e.key - (heading ?? 0)) * math.pi / 180;
      final t = TextPainter(
        text: TextSpan(
          text: e.value,
          style: TextStyle(
            color: e.key == 0 ? MihrabTokens.gold : MihrabTokens.paper,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = center + Offset(math.sin(a), -math.cos(a)) * (radius - 26);
      t.paint(canvas, p - Offset(t.width / 2, t.height / 2));
    }

    // Kaaba marker on ring
    final kaabaAngle =
        ((heading == null ? bearing : Qibla.relative(bearing, heading!))) *
            math.pi /
            180;
    final kaabaPos =
        center + Offset(math.sin(kaabaAngle), -math.cos(kaabaAngle)) * (radius - 2);
    canvas.drawCircle(
      kaabaPos,
      4,
      Paint()..color = MihrabTokens.gold,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(
      (heading == null ? bearing : Qibla.relative(bearing, heading!)) *
          math.pi /
          180,
    );
    final needle = Path()
      ..moveTo(0, -radius + 36)
      ..lineTo(-12, 18)
      ..lineTo(0, 6)
      ..lineTo(12, 18)
      ..close();
    canvas.drawPath(needle, Paint()..color = MihrabTokens.gold);
    canvas.drawPath(
      needle,
      Paint()
        ..color = MihrabTokens.goldSoft.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) =>
      oldDelegate.bearing != bearing || oldDelegate.heading != heading;
}
