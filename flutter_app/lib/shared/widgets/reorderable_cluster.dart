import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';

/// The flat index of the grid cell nearest to [local] within a [count]-item grid
/// of [columns] columns and uniform [cellW]×[cellH] cells separated by [spacing].
/// Pure so the drop math is unit-testable without a widget tree.
int clusterIndexAt(Offset local, int count, int columns, double cellW,
    double cellH, double spacing) {
  if (count <= 0) return 0;
  final cols = columns.clamp(1, count);
  final col = (local.dx / (cellW + spacing)).floor().clamp(0, cols - 1);
  var row = (local.dy / (cellH + spacing)).floor();
  if (row < 0) row = 0;
  var idx = row * cols + col;
  if (idx < 0) idx = 0;
  if (idx > count - 1) idx = count - 1;
  return idx;
}

/// An in-place, animated drag-reorder container — the iOS/Android home-widget
/// feel. Keeps the tiles exactly where they already are ([columns] wide,
/// [cellHeight] tall) in a [Stack] of [AnimatedPositioned] cells. Long-press a
/// tile to lift it (a scaled, shadowed copy follows the finger); as it hovers
/// over another slot the list re-orders *live* and every other tile slides to
/// make room. Releasing commits the new order via [onOrder].
///
/// Shown only while the home is in arrange mode, so each tile's own tap is
/// already suppressed — the long-press is unambiguous.
class ReorderableCluster extends StatefulWidget {
  final List<String> ids;
  final int columns;
  final double cellHeight;
  final double spacing;
  final Widget Function(String id) builder;
  final void Function(List<String> order) onOrder;

  /// The long-press delay before a tile lifts. Kept shorter than the enclosing
  /// section-drag delay so that long-pressing a tile reliably reorders WITHIN
  /// the cluster (this wins the gesture arena first), while long-pressing the
  /// surrounding section chrome moves the whole section.
  final Duration pressDelay;
  const ReorderableCluster({
    super.key,
    required this.ids,
    required this.columns,
    required this.cellHeight,
    required this.builder,
    required this.onOrder,
    this.spacing = Metrics.space12,
    this.pressDelay = const Duration(milliseconds: 250),
  });

  @override
  State<ReorderableCluster> createState() => _ReorderableClusterState();
}

class _ReorderableClusterState extends State<ReorderableCluster> {
  final GlobalKey _stackKey = GlobalKey();
  late List<String> _order = List.of(widget.ids);
  String? _dragId;

  @override
  void didUpdateWidget(covariant ReorderableCluster old) {
    super.didUpdateWidget(old);
    if (_dragId == null && !_sameOrder(widget.ids, _order)) {
      _order = List.of(widget.ids);
    }
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _update(Offset global, int cols, double cellW) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || _dragId == null) return;
    final local = box.globalToLocal(global);
    final target = clusterIndexAt(
        local, _order.length, cols, cellW, widget.cellHeight, widget.spacing);
    final cur = _order.indexOf(_dragId!);
    if (cur < 0 || target == cur) return;
    setState(() {
      final id = _order.removeAt(cur);
      _order.insert(target, id);
    });
  }

  void _end() {
    if (_dragId == null) return;
    setState(() => _dragId = null);
    widget.onOrder(List.of(_order));
  }

  @override
  Widget build(BuildContext context) {
    final n = _order.length;
    final cols = widget.columns.clamp(1, n == 0 ? 1 : n);
    final rows = (n / cols).ceil();
    final cellH = widget.cellHeight;
    final spacing = widget.spacing;
    return LayoutBuilder(
      builder: (context, c) {
        final cellW = (c.maxWidth - spacing * (cols - 1)) / cols;
        final height = rows <= 0 ? 0.0 : rows * cellH + (rows - 1) * spacing;
        return SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            key: _stackKey,
            children: [
              for (var i = 0; i < n; i++) _cell(i, cols, cellW, cellH, spacing),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(int i, int cols, double cellW, double cellH, double spacing) {
    final id = _order[i];
    final row = i ~/ cols;
    final col = i % cols;
    return AnimatedPositioned(
      key: ValueKey('cluster-$id'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: col * (cellW + spacing),
      top: row * (cellH + spacing),
      width: cellW,
      height: cellH,
      child: LongPressDraggable<String>(
        data: id,
        delay: widget.pressDelay,
        onDragStarted: () => setState(() => _dragId = id),
        onDragUpdate: (d) => _update(d.globalPosition, cols, cellW),
        onDragEnd: (_) => _end(),
        onDraggableCanceled: (_, __) => _end(),
        feedback: _ClusterFeedback(
            width: cellW, height: cellH, child: widget.builder(id)),
        childWhenDragging: const SizedBox.shrink(),
        child: SizedBox(
          width: cellW,
          height: cellH,
          child: widget.builder(id),
        ),
      ),
    );
  }
}

/// The lifted copy that follows the finger — the real tile, scaled up a touch
/// with a soft drop shadow so it reads as picked-up.
class _ClusterFeedback extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  const _ClusterFeedback({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width,
        height: height,
        child: Transform.scale(
          scale: 1.06,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Metrics.cornerCard),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
