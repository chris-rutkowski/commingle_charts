import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptest/taptest.dart';

import '../snapshots/_utils/tap_test_config.dart';

/// Regression guard for drill-in badge sizing when a slice's children carry
/// **raw, non-normalized values** (they do NOT sum to 1).
///
/// `ComminglePieSlice.value` magnitudes are arbitrary — siblings are shown
/// proportionally to their share of the level total. Earlier, the drill-in
/// overlay assumed children summed to 1, so every child badge was drawn at full
/// size for the whole transition and then snapped to its true size (or vanished
/// below [ComminglePieChart.minIconSweep]) the instant the level settled.
///
/// The dataset below has a dominant child plus several tiny ones whose resting
/// sweep is below `minIconSweep`; those badges must stay hidden throughout the
/// transition, and the mid-size badge must not change scale when the animation
/// settles. If the normalization regresses, the transition-frame goldens change.
abstract final class _Keys {
  static const sample = Key('pie_unnormalized_expand.chart');
}

/// Must match [ComminglePieChart]'s default animation duration.
const _animationDuration = Duration(milliseconds: 450);

const _chartSize = 160.0;
const _ringThickness = 28.0;
const _ringPadding = 4.0;
const _badgeDiameter = 14.0;

void main() {
  final controller = ComminglePieChartController();
  final slices = _unnormalizedData;
  // First top-level slice — the one with the wide range of child magnitudes.
  final expanded = slices.first;

  tapTest(
    'pie_unnormalized_expand',
    tapTestConfig(
      suite: 'pie_unnormalized_expand',
      snapshot: const SnapshotConfig(path: 'goldens/[suite]/[name].png'),
      home: _ChartHost(
        size: _chartSize,
        controller: controller,
        slices: slices,
      ),
    ),
    (tester) async {
      timeDilation = 1.0;
      await _prepareView(tester);

      // Resting top level before any interaction.
      await tester.snapshot('01_initial', key: _Keys.sample, variations: false);

      controller.expand(expanded.key);
      await tester.widgetTester.pump();
      expect(controller.path, [expanded.key]);

      // Sample the transition at a few points. With the bug, the tiny children's
      // badges appear (full size) here and the mid-size badge is oversized.
      await _pumpFractionAndSnapshot(tester, fraction: 0.40, label: '02_transition_early');
      await _pumpFractionAndSnapshot(tester, fraction: 0.70, label: '03_transition_mid');
      await _pumpFractionAndSnapshot(tester, fraction: 0.90, label: '04_transition_late');

      // Settled child level: only badges wide enough to clear minIconSweep show,
      // and they must match the size/visibility of the late transition frame.
      await tester.widgetTester.pumpAndSettle();
      expect(controller.path, [expanded.key]);
      await tester.snapshot('05_settled', key: _Keys.sample, variations: false);
    },
  );
}

Future<void> _prepareView(TapTester tester) async {
  final sampleSize = tester.widgetTester.getSize(find.byKey(_Keys.sample));
  final density = tester.config.pixelDensity;
  tester.widgetTester.view
    ..physicalSize = sampleSize * density
    ..devicePixelRatio = density;
  await tester.widgetTester.pump();
}

/// Advances the animation to [fraction] of its total duration (measured from the
/// start of the transition) and captures a frame.
Future<void> _pumpFractionAndSnapshot(
  TapTester tester, {
  required double fraction,
  required String label,
}) async {
  await tester.widgetTester.pump(_animationDuration * fraction);
  await tester.snapshot(
    label,
    key: _Keys.sample,
    variations: false,
    prePumpAndSettle: false,
  );
}

final class _ChartHost extends StatelessWidget {
  final double size;
  final ComminglePieChartController controller;
  final List<ComminglePieSlice> slices;

  const _ChartHost({
    required this.size,
    required this.controller,
    required this.slices,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox.square(
        dimension: size,
        child: RepaintBoundary(
          key: _Keys.sample,
          child: Padding(
            padding: const EdgeInsets.all(_ringPadding),
            child: ComminglePieChart(
              slices: slices,
              controller: controller,
              ringThickness: _ringThickness,
              fullIconSweep: 0.4,
              minIconSweep: 0.15,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Synthetic dummy data. Values are raw magnitudes that deliberately do NOT sum
// to 1 at any level. The first slice's children span a wide range so that a
// couple of them fall below minIconSweep at rest (badge hidden) while the rest
// are shown — the exact situation that exposed the drill-in badge bug.
// -----------------------------------------------------------------------------

List<ComminglePieSlice> get _unnormalizedData => [
  _slice('a', 500, const Color(0xFF3366CC), Icons.circle, [
    _slice('a1', 300, const Color(0xFF5C85D6), Icons.star_rounded),
    _slice('a2', 120, const Color(0xFF8FAEE3), Icons.favorite_rounded),
    _slice('a3', 40, const Color(0xFFB8CCEF), Icons.bolt_rounded),
    _slice('a4', 25, const Color(0xFFD4E0F6), Icons.eco_rounded),
    _slice('a5', 10, const Color(0xFF264D99), Icons.ac_unit_rounded),
    _slice('a6', 5, const Color(0xFF1A3366), Icons.anchor_rounded),
  ]),
  _slice('b', 220, const Color(0xFFDC3912), Icons.square_rounded),
  _slice('c', 150, const Color(0xFFFF9900), Icons.pentagon_rounded),
  _slice('d', 90, const Color(0xFF109618), Icons.hexagon_rounded),
];

ComminglePieSlice _slice(
  ComminglePieSliceKey key,
  double value,
  Color color,
  IconData icon, [
  List<ComminglePieSlice> slices = const [],
]) {
  return ComminglePieSlice(
    key: key,
    value: value,
    color: color,
    slices: slices,
    iconBuilder: (context) => _badgeIcon(icon, color),
  );
}

Widget _badgeIcon(IconData icon, Color color) {
  return Container(
    width: _badgeDiameter,
    height: _badgeDiameter,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white, width: 0.75),
    ),
    child: Icon(icon, size: 7.5, color: Colors.white),
  );
}
