import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptest/taptest.dart';

import '../snapshots/_utils/tap_test_config.dart';

/// Degenerate slice counts and value distributions for [ComminglePieChart].
/// Each case asserts the controller's drill logic (path, expand, collapse,
/// reset) and captures the resting geometry as a snapshot.
abstract final class _Keys {
  static const sample = Key('pie_edge_cases.chart');
}

const _chartSize = 320.0;
const _ringPadding = 8.0;

/// Live slices pushed into the chart from the outside, one edge case at a time.
final ValueNotifier<List<ComminglePieSlice>> _data = ValueNotifier(const []);

void main() {
  final controller = ComminglePieChartController();

  tapTest(
    'pie_edge_cases',
    tapTestConfig(
      suite: 'pie_edge_cases',
      snapshot: const SnapshotConfig(path: 'goldens/[suite]/[name].png'),
      home: _ChartHost(size: _chartSize, controller: controller),
    ),
    (tester) async {
      timeDilation = 1.0;

      // -- No sections: nothing to paint, nothing to drill into. -------------
      await _install(tester, controller, const []);
      await _prepareView(tester);
      expect(controller.path, isEmpty);
      // Expanding an empty chart is a guarded no-op — it must not throw or
      // create a phantom path entry.
      controller.expand('missing');
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, isEmpty);
      await tester.snapshot('01_no_sections', key: _Keys.sample, variations: false);

      // -- One section: a single closed ring (no near-360 seam). --------------
      final single = _equalSlices(1);
      await _install(tester, controller, single);
      expect(controller.path, isEmpty);
      await tester.snapshot('02_single_section', key: _Keys.sample, variations: false);
      // Drilling the lone leaf keeps it as the (only) level; collapsing pops
      // back to the top.
      controller.expand(single.first.key);
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, [single.first.key]);
      controller.collapse();
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, isEmpty);

      // -- 100 equal sections: uniform thin arcs, badges suppressed. ----------
      final equal = _equalSlices(100);
      await _install(tester, controller, equal);
      expect(controller.path, isEmpty);
      await tester.snapshot('03_hundred_equal', key: _Keys.sample, variations: false);
      // Any specific arc can still be addressed and drilled by key.
      controller.expand(equal[42].key);
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, [equal[42].key]);
      controller.reset();
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, isEmpty);

      // -- One dominant 75% slice plus a long tail of 99 equal slices sharing
      //    the remaining 25%. ------------------------------------------------
      final dominantTail = _dominantWithTail();
      await _install(tester, controller, dominantTail);
      expect(controller.path, isEmpty);
      await tester.snapshot('04_dominant_with_long_tail', key: _Keys.sample, variations: false);
      // The dominant arc drills like any other.
      controller.expand(dominantTail.first.key);
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, [dominantTail.first.key]);
      // A tail arc, despite being tiny, is still reachable by key.
      controller.reset();
      await tester.widgetTester.pumpAndSettle();
      controller.expand(dominantTail[1].key);
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, [dominantTail[1].key]);
      controller.reset();
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, isEmpty);
    },
  );
}

/// Clears any drill state and installs [slices] as the current data.
Future<void> _install(
  TapTester tester,
  ComminglePieChartController controller,
  List<ComminglePieSlice> slices,
) async {
  controller.reset();
  _data.value = slices;
  await tester.widgetTester.pumpAndSettle();
}

Future<void> _prepareView(TapTester tester) async {
  final sampleSize = tester.widgetTester.getSize(find.byKey(_Keys.sample));
  final density = tester.config.pixelDensity;
  tester.widgetTester.view
    ..physicalSize = sampleSize * density
    ..devicePixelRatio = density;
  await tester.widgetTester.pump();
}

final class _ChartHost extends StatelessWidget {
  final double size;
  final ComminglePieChartController controller;

  const _ChartHost({
    required this.size,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SizedBox.square(
          dimension: size,
          child: RepaintBoundary(
            key: _Keys.sample,
            child: Padding(
              padding: const EdgeInsets.all(_ringPadding),
              child: ValueListenableBuilder<List<ComminglePieSlice>>(
                valueListenable: _data,
                builder: (context, slices, _) {
                  return ComminglePieChart(
                    slices: slices,
                    controller: controller,
                    fullIconSweep: 0.4,
                    minIconSweep: 0.2,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Synthetic data generators. Values are shares of the parent; the chart
// normalises by their sum, so they need not add up to 1.
// -----------------------------------------------------------------------------

/// [count] leaf slices of identical value, each a distinct hue.
List<ComminglePieSlice> _equalSlices(int count) => [
  for (var i = 0; i < count; i++) _section(index: i, count: count, value: 1),
];

/// One dominant slice worth 75% and 99 tail slices splitting the other 25%.
List<ComminglePieSlice> _dominantWithTail() => [
  _section(index: 0, count: 100, value: 0.75),
  for (var i = 1; i < 100; i++) _section(index: i, count: 100, value: 0.25 / 99),
];

ComminglePieSlice _section({
  required int index,
  required int count,
  required double value,
}) {
  final color = HSVColor.fromAHSV(1, (index / count) * 360, 0.65, 0.9).toColor();
  final title = 'S$index';
  return ComminglePieSlice(
    key: title,
    value: value,
    color: color,
    iconBuilder: (context) => _badgeIcon(color),
    titleBuilder: (context) => Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
    valueBuilder: (context) => Text(
      '${(value * 100).round()}%',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    ),
  );
}

Widget _badgeIcon(Color color) {
  return Container(
    width: awesomePieChartDefaultBadgeDiameter,
    height: awesomePieChartDefaultBadgeDiameter,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: const Icon(Icons.pie_chart_rounded, size: 15, color: Colors.white),
  );
}
