import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// The signature recovery/domain ring gauge — a thick 270° arc filled along a
/// gradient ramp to the value fraction, with a glowing tip bead and a big
/// display number in the centre. Mirrors the Compose layered gauge.
class RingGauge extends StatelessWidget {
  /// 0..1 fill fraction.
  final double fraction;

  /// Gradient stops the arc is painted along.
  final List<Stop> stops;

  /// Centre content built by the caller (value + label).
  final Widget center;

  final double size;
  final double stroke;
  final Color? tip;

  const RingGauge({
    super.key,
    required this.fraction,
    required this.stops,
    required this.center,
    this.size = 220,
    this.stroke = 16,
    this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: Motion.durationSlow,
        curve: Motion.easeOut,
        builder: (context, f, _) => CustomPaint(
          painter: _RingPainter(
            fraction: f,
            stops: stops,
            stroke: stroke,
            tip: tip ?? Palette.tipCore,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final List<Stop> stops;
  final double stroke;
  final Color tip;

  _RingPainter({
    required this.fraction,
    required this.stops,
    required this.stroke,
    required this.tip,
  });

  static const _startAngle = math.pi * 0.75; // 135°
  static const _sweepTotal = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Palette.hairline.withValues(alpha: 0.6);
    canvas.drawArc(arcRect, _startAngle, _sweepTotal, false, track);

    // Value arc with a sweep gradient along the ramp.
    final grad = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + _sweepTotal,
      colors: Palette.gradientColors(stops),
      stops: Palette.gradientPositions(stops),
      transform: GradientRotation(_startAngle),
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = grad.createShader(arcRect);
    final sweep = _sweepTotal * fraction;
    canvas.drawArc(arcRect, _startAngle, sweep, false, arc);

    // Glowing tip bead at the arc head.
    if (fraction > 0.001) {
      final tipAngle = _startAngle + sweep;
      final tipPos = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      final tipColor = Palette.sample(stops, fraction);
      canvas.drawCircle(tipPos, stroke * 0.85,
          Paint()..color = tipColor.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(tipPos, stroke * 0.5, Paint()..color = tipColor);
      canvas.drawCircle(tipPos, stroke * 0.22, Paint()..color = tip);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.stroke != stroke || old.tip != tip;
}

/// A compact mini-gauge for the domain summary cards.
class MiniGauge extends StatelessWidget {
  final double fraction;
  final List<Stop> stops;
  final double size;
  const MiniGauge({super.key, required this.fraction, required this.stops, this.size = 46});

  @override
  Widget build(BuildContext context) => RingGauge(
        fraction: fraction,
        stops: stops,
        size: size,
        stroke: 5,
        center: const SizedBox.shrink(),
      );
}
