import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// Google-Health-style charts: a dotted line and rounded "pill" bars, in a
/// compact card variant and a large detail variant with a target band and a
/// right-hand value axis.

const _ghBlue = Color(0xFF56C2F5); // the bright cyan-blue line/dot colour
const _ghBand = Color(0xFF1F3B2A); // translucent green target band

// ── Weekday labels ──────────────────────────────────────────────────────────
String ghWeekdayInitial(DateTime d) =>
    const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];

/// The weekday label strip under a chart; the last label sits in a filled disc.
class _LabelStrip extends StatelessWidget {
  final List<String> labels;
  const _LabelStrip({required this.labels});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Center(
              child: i == labels.length - 1
                  ? Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Palette.surfaceInset,
                        shape: BoxShape.circle,
                      ),
                      child: Text(labels[i],
                          style: NoopType.caption
                              .copyWith(color: Palette.textSecondary)),
                    )
                  : Text(labels[i],
                      style: NoopType.caption
                          .copyWith(color: Palette.textTertiary)),
            ),
          ),
      ],
    );
  }
}

// ── Detailed timeline (jagged up/down line, à la Sleep Timeline) ──────────────
class HealthTimeline extends StatelessWidget {
  final List<double> values; // 0..yMax, many points
  final Color color;
  final double yMax;
  final double height;
  final List<String> axisLabels; // 3: start · mid · end
  /// Fractional x-ranges (0..1) to shade behind the line — e.g. the time spans
  /// of a selected sleep stage.
  final List<(double, double)> highlights;
  final Color? highlightColor;
  const HealthTimeline({
    super.key,
    required this.values,
    required this.color,
    required this.axisLabels,
    this.yMax = 100,
    this.height = 120,
    this.highlights = const [],
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in [yMax, yMax / 2, 0.0])
                      Text(t.round().toString(),
                          style: NoopType.caption
                              .copyWith(color: Palette.textTertiary, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: CustomPaint(
                  painter: _TimelinePainter(values, color, yMax, highlights,
                      highlightColor ?? color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Row(
            children: [
              for (var i = 0; i < axisLabels.length; i++)
                Expanded(
                  child: Align(
                    alignment: i == 0
                        ? Alignment.centerLeft
                        : (i == axisLabels.length - 1
                            ? Alignment.centerRight
                            : Alignment.center),
                    child: Text(axisLabels[i],
                        style: NoopType.caption
                            .copyWith(color: Palette.textTertiary)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<double> v;
  final Color color;
  final double yMax;
  final List<(double, double)> highlights;
  final Color highlightColor;
  _TimelinePainter(this.v, this.color, this.yMax, this.highlights, this.highlightColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Highlight bands (e.g. a selected sleep stage) behind everything.
    final band = Paint()..color = highlightColor.withValues(alpha: 0.28);
    for (final (a, b) in highlights) {
      final x0 = (a.clamp(0.0, 1.0)) * size.width;
      final x1 = (b.clamp(0.0, 1.0)) * size.width;
      canvas.drawRect(Rect.fromLTRB(x0, 0, x1 < x0 + 1.5 ? x0 + 1.5 : x1, size.height), band);
    }
    // Faint gridlines at 0 / 50 / 100 %.
    final grid = Paint()
      ..color = Palette.hairline.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (v.isEmpty) return;
    final n = v.length;
    double y(double val) =>
        size.height * (1 - (val / yMax).clamp(0.0, 1.0));
    Offset at(int i) =>
        Offset(n == 1 ? size.width / 2 : i / (n - 1) * size.width, y(v[i]));

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    // Flat, crisp jagged line — one solid colour, no gradient or glow.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.v != v || old.color != color || old.highlights != highlights;
}

// ── Mini dotted line (card) ───────────────────────────────────────────────────
class HealthMiniLine extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  const HealthMiniLine({
    super.key,
    required this.values,
    required this.labels,
    this.color = _ghBlue,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _MiniLinePainter(values, color)),
        ),
        const SizedBox(height: 8),
        _LabelStrip(labels: labels),
      ],
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  final List<double> v;
  final Color color;
  _MiniLinePainter(this.v, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.isEmpty) return;
    final lo = v.reduce(math.min), hi = v.reduce(math.max);
    final span = (hi - lo).abs() < 1e-6 ? 1.0 : (hi - lo);
    const padY = 8.0;
    Offset at(int i) {
      final x = v.length == 1 ? size.width / 2 : i / (v.length - 1) * size.width;
      final y = padY + (1 - (v[i] - lo) / span) * (size.height - 2 * padY);
      return Offset(x, y);
    }

    if (v.length >= 2) {
      final line = Path()..moveTo(at(0).dx, at(0).dy);
      for (var i = 1; i < v.length; i++) {
        line.lineTo(at(i).dx, at(i).dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < v.length; i++) {
      final last = i == v.length - 1;
      canvas.drawCircle(at(i), last ? 5.5 : 3.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_MiniLinePainter old) => old.v != v || old.color != color;
}

// ── Mini pill bars (card) ─────────────────────────────────────────────────────
class HealthMiniBars extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  const HealthMiniBars({
    super.key,
    required this.values,
    required this.labels,
    this.color = const Color(0xFF56E0C8),
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _PillPainter(values, color)),
        ),
        const SizedBox(height: 8),
        _LabelStrip(labels: labels),
      ],
    );
  }
}

class _PillPainter extends CustomPainter {
  final List<double> v;
  final Color color;
  _PillPainter(this.v, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.isEmpty) return;
    final hi = math.max(1.0, v.reduce(math.max));
    final n = v.length;
    final slot = size.width / n;
    final w = math.min(slot * 0.5, 16.0);
    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      final frac = (v[i] / hi).clamp(0.0, 1.0);
      final barH = math.max(w, frac * size.height);
      final rect = Rect.fromCenter(
          center: Offset(cx, size.height - barH / 2), width: w, height: barH);
      final on = v[i] > 0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w / 2)),
        Paint()..color = on ? color : color.withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(_PillPainter old) => old.v != v || old.color != color;
}

// ── Large detail chart ────────────────────────────────────────────────────────
enum HealthChartKind { line, bars }

/// The big detail chart: value axis on the right, an optional target band, a
/// white highlight line on the latest point, and weekday labels below.
class HealthDetailChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final HealthChartKind kind;
  final double? targetLow;
  final double? targetHigh;
  final double height;
  const HealthDetailChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = _ghBlue,
    this.kind = HealthChartKind.line,
    this.targetLow,
    this.targetHigh,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final hi = values.isEmpty ? 1.0 : values.reduce(math.max);
    final axisMax = _niceMax(math.max(hi, targetHigh ?? 0));
    final ticks = [axisMax, axisMax * 2 / 3, axisMax / 3, 0.0];
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CustomPaint(
                    painter: _DetailPainter(
                      values: values,
                      color: color,
                      kind: kind,
                      axisMax: axisMax,
                      targetLow: targetLow,
                      targetHigh: targetHigh,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Right value axis.
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in ticks)
                      Text(_fmt(t),
                          style: NoopType.caption
                              .copyWith(color: Palette.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(right: 48),
          child: _LabelStrip(labels: labels),
        ),
      ],
    );
  }

  static String _fmt(double v) {
    final n = v.round();
    final s = n.abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static double _niceMax(double v) {
    if (v <= 0) return 1;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final norm = v / mag;
    final step = norm <= 1 ? 1.0 : (norm <= 2 ? 2.0 : (norm <= 5 ? 5.0 : 10.0));
    return step * mag * (v / (step * mag)).ceil();
  }
}

class _DetailPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final HealthChartKind kind;
  final double axisMax;
  final double? targetLow, targetHigh;
  _DetailPainter({
    required this.values,
    required this.color,
    required this.kind,
    required this.axisMax,
    this.targetLow,
    this.targetHigh,
  });

  double _y(double v, double h) => h * (1 - (v / axisMax).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    // Target band.
    if (targetLow != null && targetHigh != null) {
      final top = _y(targetHigh!, h);
      final bot = _y(targetLow!, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(0, top, size.width, bot), const Radius.circular(Metrics.cornerChip)),
        Paint()..color = _ghBand.withValues(alpha: 0.7),
      );
    }
    if (values.isEmpty) return;
    final n = values.length;
    Offset at(int i) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      return Offset(x, _y(values[i], h));
    }

    // Highlight vertical line on the latest point.
    final lastX = at(n - 1).dx;
    canvas.drawLine(
      Offset(lastX, 0),
      Offset(lastX, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 1.5,
    );

    if (kind == HealthChartKind.bars) {
      final slot = size.width / n;
      final w = math.min(slot * 0.5, 22.0);
      for (var i = 0; i < n; i++) {
        final cx = at(i).dx;
        final barTop = _y(values[i], h);
        if (values[i] <= 0) continue;
        final rect = Rect.fromLTRB(cx - w / 2, barTop, cx + w / 2, h);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(w / 2)),
          Paint()..color = color,
        );
      }
    } else {
      if (n >= 2) {
        final line = Path()..moveTo(at(0).dx, at(0).dy);
        for (var i = 1; i < n; i++) {
          line.lineTo(at(i).dx, at(i).dy);
        }
        canvas.drawPath(
          line,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
      }
      for (var i = 0; i < n - 1; i++) {
        canvas.drawCircle(at(i), 3.4, Paint()..color = color);
      }
    }
    // Open ring on the latest point.
    final last = at(n - 1);
    canvas.drawCircle(last, 7, Paint()..color = Palette.surfaceBase);
    canvas.drawCircle(
        last,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_DetailPainter old) =>
      old.values != values || old.axisMax != axisMax || old.color != color;
}
