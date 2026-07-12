import 'package:flutter_test/flutter_test.dart';

import 'package:noop/shared/widgets/reorderable_cluster.dart';

void main() {
  group('clusterIndexAt', () {
    // A 2-column grid of 6 cells, 100 wide, 140 tall, 12 gap.
    const cols = 2, cellW = 100.0, cellH = 140.0, gap = 12.0, count = 6;
    int at(double x, double y) =>
        clusterIndexAt(Offset(x, y), count, cols, cellW, cellH, gap);

    test('top-left cell is index 0', () => expect(at(10, 10), 0));
    test('top-right cell is index 1', () => expect(at(160, 10), 1));
    test('second row left is index 2', () => expect(at(10, 160), 2));
    test('second row right is index 3', () => expect(at(160, 160), 3));
    test('third row left is index 4', () => expect(at(10, 320), 4));

    test('past the last row clamps to the final index', () {
      expect(at(160, 9999), count - 1);
    });
    test('negative coordinates clamp to 0', () {
      expect(at(-50, -50), 0);
    });
    test('a single row (columns == count) walks left→right', () {
      int row(double x) => clusterIndexAt(Offset(x, 10), 3, 3, 100, 118, 0);
      expect(row(10), 0);
      expect(row(150), 1);
      expect(row(250), 2);
      expect(row(9999), 2);
    });
  });
}
