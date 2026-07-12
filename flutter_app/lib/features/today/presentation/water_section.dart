import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// Home "Water" section — a user-logged hydration tracker. The liquid vessel
/// fills toward a daily goal auto-computed from the user's age; quick-add pills
/// pour in fixed millilitre amounts. There is no hydration sensor in the
/// capture, so every drop here is user-entered (never fabricated).
class WaterSection extends ConsumerWidget {
  final DayRecord day;

  /// While the home is in arrange mode the quick-add / reset pills are inert, so
  /// long-pressing the card moves the whole Water block instead of pouring water.
  final bool editing;
  const WaterSection({super.key, required this.day, this.editing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumed = ref.watch(waterLogProvider)[isoDay(day.date)] ?? 0.0;
    final goal = ref.watch(waterGoalProvider);
    final notifier = ref.read(waterLogProvider.notifier);

    // Three escalating vessels: a cup up to 200 ml, then a small bottle up to
    // 750 ml, then a large bottle you fill toward the daily goal. Each fills
    // proportionally within its own tier, and the shape switches as you drink.
    final _VesselShape shape;
    final double tierMax;
    if (consumed < 200) {
      shape = _VesselShape.cup;
      tierMax = 200;
    } else if (consumed < 750) {
      shape = _VesselShape.smallBottle;
      tierMax = 750;
    } else {
      shape = _VesselShape.largeBottle;
      tierMax = 3000; // a 3-litre bottle — it overflows past this
    }
    final rawFrac = consumed / tierMax;
    final vfrac = rawFrac.clamp(0.0, 1.0);
    final percent = (rawFrac * 100).round();
    final overflow = consumed > 3000;

    return _WaterCard(
      // The vessel sits on the left, vertically centred over the whole card
      // (crossAxisAlignment.center) against the title + quick-add column on the
      // right. No cup/bottle tag anymore.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fixed-width so the vessel + number stay centred and never shift
          // sideways as the amount grows (e.g. past a litre).
          SizedBox(
            width: 108,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WaterVessel(
                    shape: shape,
                    fraction: vfrac,
                    percent: percent,
                    overflow: overflow,
                    water: Palette.metricCyan),
                const SizedBox(height: Metrics.space8),
                Text(
                  '${_liters(consumed)} / ${_liters(goal)} L',
                  textAlign: TextAlign.center,
                  style: NoopType.caption.copyWith(color: Palette.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: Metrics.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop_rounded,
                        size: 18, color: Palette.metricCyan),
                    const SizedBox(width: Metrics.space8),
                    Text('Water',
                        style: NoopType.headline
                            .copyWith(color: Palette.textPrimary)),
                  ],
                ),
                const SizedBox(height: Metrics.space12),
                _AddPill(
                    label: '+100',
                    onTap: editing ? null : () => notifier.add(day.date, 100)),
                const SizedBox(height: Metrics.space8),
                _AddPill(
                    label: '+200',
                    onTap: editing ? null : () => notifier.add(day.date, 200)),
                const SizedBox(height: Metrics.space8),
                _AddPill(
                    label: '+250',
                    onTap: editing ? null : () => notifier.add(day.date, 250)),
                const SizedBox(height: Metrics.space8),
                _ResetPill(
                    onTap: editing ? null : () => notifier.clearDay(day.date)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Squircle, borderless card in the home surface language — a plain raised fill
/// with the section's own icon header inside.
class _WaterCard extends StatelessWidget {
  final Widget child;
  const _WaterCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(Metrics.cornerHero),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: Palette.chrome(Palette.surfaceRaised),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Palette.isLight ? 0.10 : 0.24),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Padding(
          padding: const EdgeInsets.all(Metrics.cardPadding),
          child: child,
        ),
      ),
    );
  }
}

/// A borderless quick-add pill (`+100` …), accent-tinted, on a slightly inset
/// tone so it reads on the already-raised card.
class _AddPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _AddPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Palette.fillInset,
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Metrics.space10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 15, color: Palette.accent),
                const SizedBox(width: Metrics.space6),
                Text('$label ml',
                    style: NoopType.subhead.copyWith(
                        color: Palette.accent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

/// The small "clear today" reset pill.
class _ResetPill extends StatelessWidget {
  final VoidCallback? onTap;
  const _ResetPill({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Palette.fillInset,
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Metrics.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 15, color: Palette.textTertiary),
                const SizedBox(width: Metrics.space6),
                Text('Reset',
                    style: NoopType.caption.copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
        ),
      );
}

/// Millilitres → a compact litre string, e.g. 100 → "0.1", 2500 → "2.5".
String _liters(double ml) => (ml / 1000).toStringAsFixed(1);

enum _VesselShape { cup, smallBottle, largeBottle }

/// A water vessel that changes shape with how much has been drunk — a cup, then
/// a small bottle, then a large bottle — each bigger than the last, filling from
/// the bottom to [fraction] within its own tier, percentage centred on it.
class _WaterVessel extends StatelessWidget {
  final _VesselShape shape;
  final double fraction;
  final int percent;
  final bool overflow;
  final Color water;
  const _WaterVessel({
    required this.shape,
    required this.fraction,
    required this.percent,
    required this.overflow,
    required this.water,
  });

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return SizedBox(
      width: 92,
      height: 132,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _VesselPainter(
                  shape: shape, fraction: f, water: water, overflow: overflow),
            ),
          ),
          // Centre the % on the VESSEL's own body (which sits lower in the box
          // for the smaller tiers), not on the box — so it reads centred for the
          // cup and small bottle too, not just the full-height large bottle.
          Align(
            alignment: Alignment(0, _vesselTopFrac(shape)),
            child: Text('$percent%',
                style: NoopType.number(20).copyWith(
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                )),
          ),
        ],
      ),
    );
  }
}

/// Vertical centre of each vessel's body within the box (as an Alignment y:
/// −1 top … +1 bottom), matching the [topY] used in [_vesselPath].
double _vesselTopFrac(_VesselShape s) => switch (s) {
      _VesselShape.cup => 0.40,
      _VesselShape.smallBottle => 0.18,
      _VesselShape.largeBottle => 0.0,
    };

class _VesselPainter extends CustomPainter {
  final _VesselShape shape;
  final double fraction;
  final bool overflow;
  final Color water;
  _VesselPainter({
    required this.shape,
    required this.fraction,
    required this.water,
    this.overflow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final (path, topY) = _vesselPath(size, shape);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
        Offset.zero & size, Paint()..color = water.withValues(alpha: 0.14));
    // Water surface relative to the SHAPE's own top, so the fill % matches how
    // full the drawn vessel looks (not the box).
    final waterTop = topY + (1 - fraction) * (size.height - topY);
    canvas.drawRect(
      Rect.fromLTRB(0, waterTop, size.width, size.height),
      Paint()..color = water,
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = water.withValues(alpha: 0.55),
    );

    // Over 3 litres: the bottle overflows — a little water bulges over the rim
    // and droplets spill down the sides.
    if (overflow) {
      final cx = size.width / 2;
      final fill = Paint()..color = water;
      // A rounded bulge sitting on the very top of the bottle.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, topY + 3), width: size.width * 0.36, height: 9),
          const Radius.circular(5),
        ),
        fill,
      );
      // Spilling droplets.
      canvas.drawCircle(Offset(cx - 17, topY + 16), 3.2, fill);
      canvas.drawCircle(Offset(cx + 15, topY + 22), 2.6, fill);
      canvas.drawCircle(Offset(cx + 21, topY + 9), 2.2, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _VesselPainter old) =>
      old.shape != shape ||
      old.fraction != fraction ||
      old.overflow != overflow ||
      old.water != water;
}

/// The silhouette + its top Y for a vessel [shape] within [s] — bottom-aligned
/// and centred, sized so each tier reads bigger than the last.
(Path, double) _vesselPath(Size s, _VesselShape shape) {
  final h = s.height;
  switch (shape) {
    case _VesselShape.cup:
      final topY = h * 0.40;
      return (_cupPath(s, topY), topY);
    case _VesselShape.smallBottle:
      final topY = h * 0.18;
      return (_bottlePath(s, topY, 0.48), topY);
    case _VesselShape.largeBottle:
      return (_bottlePath(s, 0, 0.66), 0);
  }
}

/// A tapered tumbler (wider at the rim) from [topY] to the bottom of [s].
Path _cupPath(Size s, double topY) {
  final w = s.width, h = s.height, cx = w / 2;
  final topW = w * 0.58, botW = w * 0.44;
  final topL = cx - topW / 2, topR = cx + topW / 2;
  final botL = cx - botW / 2, botR = cx + botW / 2;
  final r = botW * 0.18;
  return Path()
    ..moveTo(topL, topY)
    ..lineTo(topR, topY)
    ..lineTo(botR, h - r)
    ..quadraticBezierTo(botR, h, botR - r, h)
    ..lineTo(botL + r, h)
    ..quadraticBezierTo(botL, h, botL, h - r)
    ..lineTo(topL, topY)
    ..close();
}

/// A bottle (cap · neck · shoulder · rounded body) filling [s] from [topY] down,
/// its body [bodyWFrac] of the width.
Path _bottlePath(Size s, double topY, double bodyWFrac) {
  final w = s.width, h = s.height, cx = w / 2;
  final vh = h - topY;
  final bodyW = w * bodyWFrac;
  final neckW = bodyW * 0.30;
  final capW = bodyW * 0.40;
  final capL = cx - capW / 2, capR = cx + capW / 2;
  final neckL = cx - neckW / 2, neckR = cx + neckW / 2;
  final bodyL = cx - bodyW / 2, bodyR = cx + bodyW / 2;
  final capBottom = topY + vh * 0.06;
  final neckBottom = topY + vh * 0.19;
  final shoulder = topY + vh * 0.31;
  final bottom = h;
  final r = bodyW * 0.18;
  return Path()
    ..moveTo(capL, topY)
    ..lineTo(capR, topY)
    ..lineTo(capR, capBottom)
    ..lineTo(neckR, capBottom)
    ..lineTo(neckR, neckBottom)
    ..quadraticBezierTo(bodyR, neckBottom, bodyR, shoulder)
    ..lineTo(bodyR, bottom - r)
    ..quadraticBezierTo(bodyR, bottom, bodyR - r, bottom)
    ..lineTo(bodyL + r, bottom)
    ..quadraticBezierTo(bodyL, bottom, bodyL, bottom - r)
    ..lineTo(bodyL, shoulder)
    ..quadraticBezierTo(bodyL, neckBottom, neckL, neckBottom)
    ..lineTo(neckL, capBottom)
    ..lineTo(capL, capBottom)
    ..close();
}
