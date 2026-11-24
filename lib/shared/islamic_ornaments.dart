import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../app/theme.dart';

/// Thin geometric star used as a focal ornament.
class IslamicStar extends StatelessWidget {
  const IslamicStar({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidth = 1.2,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (dark ? MihrabTokens.gold : MihrabTokens.emerald);
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(c, strokeWidth),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.color, this.strokeWidth);
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round;

    // 8-point geometric star (two squares)
    Path square(double rotation) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rotation + i * math.pi / 2;
        final p = Offset(
          center.dx + r * math.cos(a),
          center.dy + r * math.sin(a),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      return path;
    }

    canvas.drawPath(square(-math.pi / 4), paint);
    canvas.drawPath(square(0), paint);
    canvas.drawCircle(center, r * 0.22, paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Horizontal divider with a central star.
class IslamicDivider extends StatelessWidget {
  const IslamicDivider({super.key, this.padding = 12});

  final double padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color =
        dark
            ? MihrabTokens.gold.withValues(alpha: 0.35)
            : MihrabTokens.emerald.withValues(alpha: 0.22);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IslamicStar(size: 14, color: color, strokeWidth: 1),
          ),
          Expanded(child: Divider(color: color, thickness: 0.8)),
        ],
      ),
    );
  }
}

/// Section label in uppercase with letter-spacing.
class IslamicSectionTitle extends StatelessWidget {
  const IslamicSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.8,
          fontWeight: FontWeight.w600,
          color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
        ),
      ),
    );
  }
}

/// Soft card shell used across secondary screens.
class IslamicCard extends StatelessWidget {
  const IslamicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color:
            highlighted
                ? MihrabTokens.emerald
                : (dark
                    ? MihrabTokens.emerald.withValues(alpha: 0.4)
                    : MihrabTokens.paper),
        borderRadius: BorderRadius.circular(MihrabTokens.radius),
        border: Border.all(
          color:
              highlighted
                  ? MihrabTokens.gold.withValues(alpha: 0.4)
                  : (dark
                      ? MihrabTokens.gold.withValues(alpha: 0.1)
                      : MihrabTokens.emerald.withValues(alpha: 0.07)),
        ),
        boxShadow:
            highlighted
                ? [
                  BoxShadow(
                    color: MihrabTokens.emeraldDeep.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
                : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(MihrabTokens.radius),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Mihrab-like arch frame for hero blocks.
class MihrabFrame extends StatelessWidget {
  const MihrabFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 32, 24, 28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MihrabTokens.emeraldSoft,
            MihrabTokens.emerald,
            MihrabTokens.emeraldDeep,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.elliptical(150, 68),
          topRight: Radius.elliptical(150, 68),
          bottomLeft: Radius.circular(MihrabTokens.radiusLg),
          bottomRight: Radius.circular(MihrabTokens.radiusLg),
        ),
        border: Border.all(
          color: MihrabTokens.gold.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: MihrabTokens.emeraldDeep.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
