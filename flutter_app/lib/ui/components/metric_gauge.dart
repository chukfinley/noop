import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/prefs.dart';
import '../../state/providers.dart';
import '../theme/palette.dart';
import 'liquid.dart';

/// The colour a gauge's centred number/label should use for [style]. The liquid
/// vessel sits on saturated fluid → white (with a soft shadow) in both themes;
/// the ring sits on the card surface → the primary text colour, which is
/// near-white in dark and near-black in light. Callers use these instead of
/// hardcoding white, so the number stays legible in every style × theme combo.
Color gaugeCenterColor(GaugeStyle style) =>
    style == GaugeStyle.ring ? Palette.textPrimary : Colors.white;

/// Shadow for a gauge's centred text — only the liquid vessel needs one (to lift
/// white off the fluid); on the ring the text sits flat on the card.
List<Shadow> gaugeCenterShadows(GaugeStyle style) => style == GaugeStyle.ring
    ? const []
    : const [Shadow(color: Colors.black54, blurRadius: 6)];

/// The user-switchable score dial. Renders either the animated liquid vessel or
/// a simple full ring, driven by [gaugeStyleProvider], from one call site — so
/// every hero gauge across the app flips together with the setting.
class MetricGauge extends ConsumerWidget {
  final double fraction;
  final List<Stop> ramp;
  final double size;
  final Widget? center;

  /// Ring stroke thickness; defaults proportional to [size].
  final double? stroke;

  const MetricGauge({
    super.key,
    required this.fraction,
    required this.ramp,
    this.size = 120,
    this.center,
    this.stroke,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(gaugeStyleProvider);
    if (style == GaugeStyle.ring) {
      return _FullRing(
        base: Palette.sample(ramp, fraction.clamp(0, 1)),
        size: size,
        stroke: stroke ?? (size * 0.11).clamp(6.0, 18.0),
        center: center,
      );
    }
    return LiquidVessel(
      fraction: fraction,
      ramp: ramp,
      size: size,
      showRim: false,
      center: center,
    );
  }
}

/// A complete 360° ring — no arc gap, no tip bead. A light→dark gradient starts
/// at top-centre and sweeps symmetrically down both sides (top lit, bottom deep).
class _FullRing extends StatelessWidget {
  final Color base;
  final double size;
  final double stroke;
  final Widget? center;
  const _FullRing({
    required this.base,
    required this.size,
    required this.stroke,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FullRingPainter(base: base, stroke: stroke),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _FullRingPainter extends CustomPainter {
  final Color base;
  final double stroke;
  _FullRingPainter({required this.base, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (math.min(size.width, size.height) - stroke) / 2;
    if (r <= 0) return;

    // Faint full track underneath — dark-on-light or light-on-dark per theme.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = (Palette.isLight ? Colors.black : Colors.white)
            .withValues(alpha: Palette.isLight ? 0.06 : 0.05),
    );

    final light = Color.lerp(base, Colors.white, 0.30)!;
    final dark = Color.lerp(base, Colors.black, 0.40)!;
    final shader = SweepGradient(
      colors: [light, dark, light],
      stops: const [0.0, 0.5, 1.0],
      // Rotate so the gradient's start (light) sits at top-centre.
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_FullRingPainter old) => old.base != base || old.stroke != stroke;
}
