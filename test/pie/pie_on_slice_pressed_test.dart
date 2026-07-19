import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Two equal leaf slices. With the chart's -90 degree start offset, section 0
// sweeps the right half (midpoint at 3 o'clock) and section 1 the left half.
final _slices = <ComminglePieSlice>[
  ComminglePieSlice(
    key: 'right',
    value: 1,
    color: const Color(0xFFE53935),
    iconBuilder: (context) => const SizedBox.shrink(),
  ),
  ComminglePieSlice(
    key: 'left',
    value: 1,
    color: const Color(0xFF1E88E5),
    iconBuilder: (context) => const SizedBox.shrink(),
  ),
];

const _size = 200.0;
const _ringThickness = 40.0;

void main() {
  testWidgets('onSlicePressed fires with the tapped slice key on a user tap', (tester) async {
    final controller = ComminglePieChartController();
    addTearDown(controller.dispose);
    final pressed = <ComminglePieSliceKey>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: _size,
            child: ComminglePieChart(
              slices: _slices,
              controller: controller,
              ringThickness: _ringThickness,
              onSlicePressed: pressed.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byType(ComminglePieChart));
    final center = rect.center;
    // Mid-ring radius: halfway through the painted ring.
    final midRadius = (_size / 2 - _ringThickness) + _ringThickness / 2;

    // Tap the right-half section (index 0, key 'right').
    await tester.tapAt(Offset(center.dx + midRadius, center.dy));
    await tester.pump();
    expect(pressed, ['right']);

    // Return to the two-slice level so the second section is tappable again.
    controller.reset();
    await tester.pumpAndSettle();

    // Tap the left-half section (index 1, key 'left').
    await tester.tapAt(Offset(center.dx - midRadius, center.dy));
    await tester.pump();
    expect(pressed, ['right', 'left']);
  });

  testWidgets('onSlicePressed stays silent for programmatic controller.expand', (tester) async {
    final controller = ComminglePieChartController();
    addTearDown(controller.dispose);
    final pressed = <ComminglePieSliceKey>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: _size,
            child: ComminglePieChart(
              slices: _slices,
              controller: controller,
              ringThickness: _ringThickness,
              onSlicePressed: pressed.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.expand('right');
    await tester.pumpAndSettle();

    expect(controller.path, ['right']);
    expect(pressed, isEmpty);
  });
}
