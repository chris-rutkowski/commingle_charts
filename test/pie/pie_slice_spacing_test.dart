import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptest/taptest.dart';

import '../snapshots/_utils/tap_test_config.dart';

/// Captures the resting geometry of [ComminglePieChart.sliceSpacing] across a
/// single-slice level (where spacing has no effect) and a two-slice level at
/// zero, default (2.5), and double-the-default (5.0) spacing.
abstract final class _Keys {
  static const sample = Key('pie_slice_spacing.chart');
}

const _chartSize = 320.0;
const _ringPadding = 8.0;
const _defaultSpacing = 2.5;

/// Slices pushed into the chart from the outside, one case at a time.
final ValueNotifier<List<ComminglePieSlice>> _data = ValueNotifier(const []);

/// Live slice spacing for the current case.
final ValueNotifier<double> _spacing = ValueNotifier(_defaultSpacing);

void main() {
  tapTest(
    'pie_slice_spacing',
    tapTestConfig(
      suite: 'pie_slice_spacing',
      snapshot: const SnapshotConfig(path: 'goldens/[suite]/[name].png'),
      home: const _ChartHost(size: _chartSize),
    ),
    (tester) async {
      timeDilation = 1.0;

      // Single slice: renders as a closed ring, so spacing is irrelevant.
      await _install(tester, _equalSlices(1), _defaultSpacing);
      await _prepareView(tester);
      await tester.snapshot('01_single_default_spacing', key: _Keys.sample, variations: false);

      // Two slices, no gap between them.
      await _install(tester, _equalSlices(2), 0);
      await tester.snapshot('02_two_zero_spacing', key: _Keys.sample, variations: false);

      // Two slices at the default spacing (2.5).
      await _install(tester, _equalSlices(2), _defaultSpacing);
      await tester.snapshot('03_two_default_spacing', key: _Keys.sample, variations: false);

      // Two slices at twice the default spacing (5.0).
      await _install(tester, _equalSlices(2), _defaultSpacing * 2);
      await tester.snapshot('04_two_double_spacing', key: _Keys.sample, variations: false);
    },
  );
}

/// Installs [slices] and [spacing] as the current case and settles the frame.
Future<void> _install(
  TapTester tester,
  List<ComminglePieSlice> slices,
  double spacing,
) async {
  _data.value = slices;
  _spacing.value = spacing;
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

  const _ChartHost({required this.size});

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
              child: ListenableBuilder(
                listenable: Listenable.merge([_data, _spacing]),
                builder: (context, _) {
                  return ComminglePieChart(
                    slices: _data.value,
                    sliceSpacing: _spacing.value,
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

/// [count] leaf slices of identical value, each a distinct hue.
List<ComminglePieSlice> _equalSlices(int count) => [
  for (var i = 0; i < count; i++) _section(index: i, count: count),
];

ComminglePieSlice _section({required int index, required int count}) {
  final color = HSVColor.fromAHSV(1, (index / count) * 360, 0.65, 0.9).toColor();
  final title = 'S$index';
  return ComminglePieSlice(
    key: title,
    value: 1,
    color: color,
    iconBuilder: (context) => _badgeIcon(color),
  );
}

Widget _badgeIcon(Color color) {
  return Container(
    width: 28.0,
    height: 28.0,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: const Icon(Icons.pie_chart_rounded, size: 15, color: Colors.white),
  );
}
