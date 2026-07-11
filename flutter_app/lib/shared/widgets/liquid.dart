import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:noop/core/theme/palette.dart';

/// Lightweight liquid-surface sim — two free-running wave phases plus optional
/// spring-slosh angles. Faithful port of the noop `LiquidSim` (tilt fed as 0, so
/// the springs settle flat and the phase integrators carry the undulation).
class LiquidSim {
  double level; // eased fill 0..1
  double target;
  double a = 0, av = 0; // front surface spring angle
  double ab = 0, abv = 0; // back surface spring angle
  double energy;
  double p1 = 0, p2 = 0; // wave phases
  double _last = 0;

  LiquidSim(this.target, {this.energy = 0.35}) : level = target;

  static const _kSpring = 31.0, _cSpring = 5.5;
  static const _kBack = 20.0, _cBack = 4.3;
  static const _phaseMul = 0.85;

  void step(double now, {double tilt = 0}) {
    var dt = _last == 0 ? 0.016 : (now - _last);
    _last = now;
    if (dt <= 0) return;
    if (dt > 0.033) dt = 0.033;

    final surfTarget = -tilt;
    av += (_kSpring * (surfTarget - a) - _cSpring * av) * dt;
    a = (a + av * dt).clamp(-0.6, 0.6);
    abv += (_kBack * (surfTarget - ab) - _cBack * abv) * dt;
    ab = (ab + abv * dt).clamp(-0.66, 0.66);

    final d = target - level;
    if (d.abs() > 0.0004) {
      level += d * math.min(1, dt * 2.6);
      energy += d.abs() * dt * 6;
    }

    final speed = (1 + energy * 2.2) * _phaseMul;
    p1 += dt * 2.1 * speed;
    p2 += dt * 3.3 * speed;

    // Hold a gentle floor so the surface always breathes (no sensor input).
    energy *= math.exp(-dt * 1.5);
    if (energy < 0.28) energy = 0.28;
  }
}

/// A circular vessel filled with animated "water" to [fraction], tinted by
/// sampling [ramp] at the fill level. Mirrors noop's LiquidVessel / HeroScoreVessel.
class LiquidVessel extends StatefulWidget {
  final double fraction;
  final List<Stop> ramp;
  final double size;
  final Widget? center;
  final bool animate;
  final bool showRim;

  const LiquidVessel({
    super.key,
    required this.fraction,
    required this.ramp,
    this.size = 160,
    this.center,
    this.animate = true,
    this.showRim = true,
  });

  @override
  State<LiquidVessel> createState() => _LiquidVesselState();
}

class _LiquidVesselState extends State<LiquidVessel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late LiquidSim _sim;

  @override
  void initState() {
    super.initState();
    _sim = LiquidSim(widget.fraction.clamp(0.0, 1.0));
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 30));
    if (widget.animate) {
      _c.repeat();
    }
  }

  @override
  void didUpdateWidget(LiquidVessel old) {
    super.didUpdateWidget(old);
    if (old.fraction != widget.fraction) {
      _sim.target = widget.fraction.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = Palette.sample(widget.ramp, widget.fraction.clamp(0.0, 1.0));
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final now = _c.lastElapsedDuration?.inMicroseconds ?? 0;
          _sim.step(now / 1e6);
          return CustomPaint(
            painter: _VesselPainter(_sim, tint, widget.showRim),
            child: child,
          );
        },
        child: widget.center == null ? null : Center(child: widget.center),
      ),
    );
  }
}

class _VesselPainter extends CustomPainter {
  final LiquidSim sim;
  final Color tint;
  final bool showRim;
  _VesselPainter(this.sim, this.tint, [this.showRim = true]);

  static Color _darker(Color c, double t) =>
      Color.lerp(c, Colors.black, t)!.withValues(alpha: 1);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 1.5;

    // Vessel well behind the liquid — a dark recess in dark mode; a pale cool
    // grey in light mode so the vessel reads as a soft cup on a white card
    // instead of a dark blob.
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Palette.isLight
            ? const Color(0xFFE7EAEF)
            : const Color(0xFF0A0B10).withValues(alpha: 0.55),
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));

    final lv = sim.level.clamp(0.0, 1.0);
    if (lv > 0.004) {
      final energy = sim.energy;
      final amp = (0.018 + energy * 0.09) * r;
      final k1 = 2 * math.pi / (r * 1.5);
      final k2 = 2 * math.pi / (r * 0.95);
      final sy = r * (1 - 2 * math.min(0.985, lv));

      double chordHW(double depth) =>
          math.max(r * 0.3, math.sqrt(math.max(0, r * r - depth * depth)));

      double surfaceY(double x, double hw, double ph1, double ph2, double ampMul) {
        final xs = x.clamp(-hw, hw);
        var y = amp * ampMul * math.sin(x * k1 + ph1) +
            amp * ampMul * 0.6 * math.sin(x * k2 - ph2);
        y += -0.01 * r * math.pow((xs.abs() / hw), 4);
        return y;
      }

      final ext = r * 1.8;

      Path wavePath(double hw, double ph1, double ph2, double ampMul) {
        final p = Path();
        var first = true;
        for (double x = -ext; x <= ext; x += 4) {
          final y = surfaceY(x, hw, ph1, ph2, ampMul);
          if (first) {
            p.moveTo(x, y);
            first = false;
          } else {
            p.lineTo(x, y);
          }
        }
        p.lineTo(ext, r * 2.4);
        p.lineTo(-ext, r * 2.4);
        p.close();
        return p;
      }

      // Back parallax wave.
      final syB = sy - r * 0.04;
      final hwB = chordHW(syB);
      canvas.save();
      canvas.translate(0, syB);
      canvas.rotate(sim.ab);
      canvas.drawPath(
        wavePath(hwB, sim.p1 * 0.92 + 2.1, sim.p2 * 0.90 + 1.3, 1.35),
        Paint()..color = tint.withValues(alpha: 0.28),
      );
      canvas.restore();

      // Main body.
      final hw = chordHW(sy);
      canvas.save();
      canvas.translate(0, sy);
      canvas.rotate(sim.a);
      final body = wavePath(hw, sim.p1, sim.p2, 1.0);
      canvas.drawPath(
        body,
        Paint()
          ..shader = _vGrad(
            const Offset(0, 0),
            Offset(0, r * 1.7),
            [tint.withValues(alpha: 0.74), _darker(tint, 0.28).withValues(alpha: 0.80)],
          ),
      );

      // Gliding specular band, clipped to the body.
      canvas.save();
      canvas.clipPath(body);
      final bandX = -sim.a * r * 2.2 + math.sin(sim.p1 * 0.3) * r * 0.15;
      canvas.drawRect(
        Rect.fromLTRB(bandX - r * 1.2, -r, bandX + r * 1.2, r * 2),
        Paint()
          ..shader = _vGradH(
            Offset(bandX - r * 1.2, 0),
            Offset(bandX + r * 1.2, 0),
            [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.06),
              Colors.white.withValues(alpha: 0),
            ],
            [0, 0.5, 1],
          ),
      );
      canvas.restore();

      // Surface glints where the surface is near-flat.
      final glint = Paint()..color = Colors.white;
      for (double gx = -hw; gx <= hw; gx += 6) {
        final slope =
            (surfaceY(gx + 3, hw, sim.p1, sim.p2, 1) - surfaceY(gx - 3, hw, sim.p1, sim.p2, 1)) / 6;
        if (slope.abs() < 0.05) {
          final gy = surfaceY(gx, hw, sim.p1, sim.p2, 1);
          canvas.drawRect(
            Rect.fromLTWH(gx, gy - 0.7, 4, 1.4),
            glint..color = Colors.white.withValues(alpha: 0.22 * (1 - slope.abs() / 0.05)),
          );
        }
      }

      // (No hard surface line — the waves read as a soft, playful meniscus.)
      canvas.restore();

      // Inner top shadow + top-left highlight.
      canvas.drawRect(
        Rect.fromLTRB(-r, -r, r, -r * 0.30),
        Paint()
          ..shader = _vGrad(Offset(0, -r), Offset(0, -r * 0.30),
              [Colors.black.withValues(alpha: 0.30), Colors.black.withValues(alpha: 0)]),
      );
      canvas.drawCircle(
        Offset(-r * 0.27, -r * 0.5),
        r * 0.55,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: 0.09),
            Colors.white.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: Offset(-r * 0.27, -r * 0.5), radius: r * 0.55)),
      );
    }

    canvas.restore();

    // Outer rim.
    if (showRim) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25
          ..color = tint.withValues(alpha: 0.22),
      );
    }
  }

  Shader _vGrad(Offset from, Offset to, List<Color> colors, [List<double>? stops]) =>
      ui.Gradient.linear(from, to, colors, stops);

  Shader _vGradH(Offset from, Offset to, List<Color> colors, [List<double>? stops]) =>
      ui.Gradient.linear(from, to, colors, stops);

  @override
  bool shouldRepaint(_VesselPainter old) => true;
}
