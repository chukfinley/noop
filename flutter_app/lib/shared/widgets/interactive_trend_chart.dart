import 'package:flutter/material.dart';

import 'package:noop/core/state/format.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

enum TrendChartKind { line, bars }

/// The one large, **interactive** trend chart behind every metric detail screen.
///
/// Drag a finger across it (or tap) and a vertical scrubber line snaps to the
/// nearest day, highlighting its point and floating a readout with that day's
/// date + value — so you can inspect every day, not just the latest. A value
/// axis (right), light gridlines, an optional personal-range band and clear
/// x-axis date labels make it properly legible.
class InteractiveTrendChart extends StatefulWidget {
  final List<double> values; // oldest → newest
  final List<DateTime> dates; // aligned with [values]
  final List<String> labels; // x-axis labels, aligned with [values]
  final Color color;
  final TrendChartKind kind;
  final double? targetLow;
  final double? targetHigh;
  final String Function(double v) fmt;
  final String unit;
  final double height;

  const InteractiveTrendChart({
    super.key,
    required this.values,
    required this.dates,
    required this.labels,
    required this.color,
    required this.fmt,
    this.kind = TrendChartKind.line,
    this.targetLow,
    this.targetHigh,
    this.unit = '',
    this.height = 224,
  });

  @override
  State<InteractiveTrendChart> createState() => _InteractiveTrendChartState();
}

class _InteractiveTrendChartState extends State<InteractiveTrendChart> {
  int? _active;

  static const _leftPad = 8.0;
  static const _rightPad = 42.0;
  static const _topPad = 16.0;
  static const _botPad = 26.0;

  (double, double) _domain() {
    final vs = widget.values.where((v) => v.isFinite).toList();
    var lo = vs.isEmpty ? 0.0 : vs.reduce((a, b) => a < b ? a : b);
    var hi = vs.isEmpty ? 1.0 : vs.reduce((a, b) => a > b ? a : b);
    if (widget.targetLow != null && widget.targetLow! < lo) lo = widget.targetLow!;
    if (widget.targetHigh != null && widget.targetHigh! > hi) hi = widget.targetHigh!;
    if ((hi - lo).abs() < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.12;
    return (lo - pad, hi + pad);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.values.length;
    final (minV, maxV) = _domain();

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final plotL = _leftPad;
      final plotR = w - _rightPad;
      final plotW = (plotR - plotL) < 1 ? 1.0 : (plotR - plotL);
      double xOf(int i) =>
          n <= 1 ? plotL + plotW / 2 : plotL + i / (n - 1) * plotW;

      void setFromDx(double dx) {
        if (n == 0) return;
        final i = n <= 1
            ? 0
            : ((dx - plotL) / plotW * (n - 1)).round().clamp(0, n - 1);
        if (i != _active) setState(() => _active = i);
      }

      Widget? tip;
      final a = _active;
      if (a != null && a < n) {
        final x = xOf(a);
        final left = (x - 54).clamp(0.0, (w - 108).clamp(0.0, w));
        tip = Positioned(
          left: left,
          top: 0,
          child: _Readout(
            date: widget.dates.length > a ? widget.dates[a] : null,
            value: '${widget.fmt(widget.values[a])}'
                '${widget.unit.isNotEmpty ? ' ${widget.unit}' : ''}',
            color: widget.color,
          ),
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => setFromDx(d.localPosition.dx),
        onHorizontalDragStart: (d) => setFromDx(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => setFromDx(d.localPosition.dx),
        child: SizedBox(
          height: widget.height,
          width: w,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrendPainter(
                    values: widget.values,
                    dates: widget.dates,
                    labels: widget.labels,
                    minV: minV,
                    maxV: maxV,
                    color: widget.color,
                    kind: widget.kind,
                    targetLow: widget.targetLow,
                    targetHigh: widget.targetHigh,
                    fmt: widget.fmt,
                    active: a,
                    leftPad: _leftPad,
                    rightPad: _rightPad,
                    topPad: _topPad,
                    botPad: _botPad,
                  ),
                ),
              ),
              if (tip != null) tip,
            ],
          ),
        ),
      );
    });
  }
}

/// The floating value+date pill that follows the scrubber.
class _Readout extends StatelessWidget {
  final DateTime? date;
  final String value;
  final Color color;
  const _Readout({required this.date, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.fillRaised,
        borderRadius: BorderRadius.circular(Metrics.cornerChip),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Palette.isLight ? 0.10 : 0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null)
            Text(Fmt.shortDate(date!),
                style: NoopType.caption.copyWith(color: Palette.textTertiary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Text(value,
                  style: NoopType.number(16)
                      .copyWith(color: Palette.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final List<DateTime> dates;
  final List<String> labels;
  final double minV, maxV;
  final Color color;
  final TrendChartKind kind;
  final double? targetLow, targetHigh;
  final String Function(double) fmt;
  final int? active;
  final double leftPad, rightPad, topPad, botPad;

  _TrendPainter({
    required this.values,
    required this.dates,
    required this.labels,
    required this.minV,
    required this.maxV,
    required this.color,
    required this.kind,
    required this.targetLow,
    required this.targetHigh,
    required this.fmt,
    required this.active,
    required this.leftPad,
    required this.rightPad,
    required this.topPad,
    required this.botPad,
  });

  TextPainter _tp(String s, Color c, double size,
      {FontWeight w = FontWeight.w500}) {
    final t = TextPainter(
      text: TextSpan(
          text: s,
          style: NoopType.caption
              .copyWith(color: c, fontSize: size, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    return t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final plotL = leftPad;
    final plotR = size.width - rightPad;
    final plotT = topPad;
    final plotB = size.height - botPad;
    final plotW = plotR - plotL;
    final plotH = plotB - plotT;
    double xOf(int i) => n <= 1 ? plotL + plotW / 2 : plotL + i / (n - 1) * plotW;
    double yOf(double v) =>
        plotB - ((v - minV) / (maxV - minV)).clamp(0.0, 1.0) * plotH;

    // Gridlines + right value-axis labels.
    final grid = Paint()
      ..color = Palette.textTertiary.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final frac = t / ticks;
      final y = plotT + frac * plotH;
      canvas.drawLine(Offset(plotL, y), Offset(plotR, y), grid);
      final v = maxV - frac * (maxV - minV);
      final lp = _tp(fmt(v), Palette.textTertiary, 10);
      lp.paint(canvas, Offset(plotR + 6, y - lp.height / 2));
    }

    // Personal-range band.
    if (targetLow != null && targetHigh != null) {
      final yTop = yOf(targetHigh!);
      final yBot = yOf(targetLow!);
      canvas.drawRect(
        Rect.fromLTRB(plotL, yTop, plotR, yBot),
        Paint()..color = Palette.statusPositive.withValues(alpha: 0.10),
      );
    }

    if (n == 0) return;

    // Series.
    if (kind == TrendChartKind.bars) {
      final bw = n <= 1 ? plotW * 0.4 : (plotW / n) * 0.62;
      for (var i = 0; i < n; i++) {
        final x = xOf(i);
        final y = yOf(values[i]);
        final on = active == i;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTRB(x - bw / 2, y, x + bw / 2, plotB),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = color.withValues(alpha: on ? 1.0 : 0.78),
        );
      }
    } else {
      final line = Path();
      final fill = Path();
      for (var i = 0; i < n; i++) {
        final x = xOf(i);
        final y = yOf(values[i]);
        if (i == 0) {
          line.moveTo(x, y);
          fill.moveTo(x, plotB);
          fill.lineTo(x, y);
        } else {
          line.lineTo(x, y);
          fill.lineTo(x, y);
        }
      }
      fill.lineTo(xOf(n - 1), plotB);
      fill.close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTRB(plotL, plotT, plotR, plotB)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      if (n <= 31) {
        for (var i = 0; i < n; i++) {
          canvas.drawCircle(
              Offset(xOf(i), yOf(values[i])), 2.6, Paint()..color = color);
        }
      }
    }

    // X-axis labels — sample evenly so they never crowd.
    final labelCount = n <= 1 ? 1 : (n <= 7 ? n : 6);
    for (var k = 0; k < labelCount; k++) {
      final i = labelCount == 1
          ? 0
          : (k * (n - 1) / (labelCount - 1)).round().clamp(0, n - 1);
      final s = labels.length > i ? labels[i] : '';
      if (s.isEmpty) continue;
      final lp = _tp(s, Palette.textTertiary, 10);
      lp.paint(canvas, Offset(xOf(i) - lp.width / 2, plotB + 6));
    }

    // Scrubber.
    if (active != null && active! < n) {
      final x = xOf(active!);
      final y = yOf(values[active!]);
      canvas.drawLine(
        Offset(x, plotT),
        Offset(x, plotB),
        Paint()
          ..color = Palette.textSecondary.withValues(alpha: 0.55)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(Offset(x, y), 7.5, Paint()..color = Palette.surfaceBase);
      canvas.drawCircle(Offset(x, y), 6.5, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.active != active ||
      old.values != values ||
      old.minV != minV ||
      old.maxV != maxV ||
      old.color != color ||
      old.kind != kind;
}
