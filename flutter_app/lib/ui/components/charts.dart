import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

/// A tiny sparkline — a smoothed line over a value series with a soft fill and a
/// bright head bead. Value-tinted along an optional ramp.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final List<Stop>? ramp;
  final double width;
  final double height;
  final bool fill;

  const Sparkline({
    super.key,
    required this.values,
    this.color,
    this.ramp,
    this.width = Metrics.sparkWidth,
    this.height = Metrics.sparkHeight,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparkPainter(
            values: values,
            color: color ?? Palette.accent,
            ramp: ramp,
            fill: fill,
          ),
        ),
      );
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final List<Stop>? ramp;
  final bool fill;
  _SparkPainter({required this.values, required this.color, this.ramp, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = (hi - lo).abs() < 1e-6 ? 1.0 : (hi - lo);
    final dx = size.width / (values.length - 1);
    Offset pt(int i) => Offset(
          i * dx,
          size.height - ((values[i] - lo) / span) * size.height,
        );

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p0 = pt(i - 1), p1 = pt(i);
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final headColor = ramp != null
        ? Palette.sample(ramp!, (values.last - lo) / span)
        : color;

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              headColor.withValues(alpha: StrandAlpha.chartFillStrong),
              headColor.withValues(alpha: StrandAlpha.chartFillSoft),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = headColor,
    );

    final head = pt(values.length - 1);
    canvas.drawCircle(head, 2.6, Paint()..color = Palette.tipCore);
    canvas.drawCircle(head, 4.5,
        Paint()..color = headColor.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}

/// A horizontal segmented bar (sleep-stage strip / domain breakdown).
class SegmentBar extends StatelessWidget {
  final List<SegmentDatum> segments;
  final double height;
  const SegmentBar(this.segments, {super.key, this.height = Metrics.segmentBarHeight});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Metrics.cornerBadge),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final s in segments)
              Expanded(
                flex: total <= 0 ? 1 : (s.value / total * 1000).round().clamp(1, 1000000),
                child: Container(color: s.color),
              ),
          ],
        ),
      ),
    );
  }
}

class SegmentDatum {
  final double value;
  final Color color;
  final String? label;
  const SegmentDatum(this.value, this.color, {this.label});
}

/// A grouped bar chart column series (trends). Bars tinted along a ramp by value.
class BarSeries extends StatelessWidget {
  final List<double> values;
  final List<Stop>? ramp;
  final Color? color;
  final double height;
  final double maxValue;
  final int? highlightIndex;
  final ValueChanged<int>? onTap;

  const BarSeries({
    super.key,
    required this.values,
    this.ramp,
    this.color,
    this.height = Metrics.chartHeight,
    required this.maxValue,
    this.highlightIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, c) {
        final n = values.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: GestureDetector(
                  onTap: onTap == null ? null : () => onTap!(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor:
                            maxValue <= 0 ? 0 : (values[i] / maxValue).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: (ramp != null
                                    ? Palette.sample(ramp!, values[i] / maxValue)
                                    : (color ?? Palette.accent))
                                .withValues(
                                    alpha: highlightIndex == null || highlightIndex == i
                                        ? StrandAlpha.unselectedBar
                                        : 0.4),
                            borderRadius: BorderRadius.circular(Metrics.cornerBadge),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
