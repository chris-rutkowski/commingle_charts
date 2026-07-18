import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptest/taptest.dart';

import '../snapshots/_utils/tap_test_config.dart';

abstract final class _Keys {
  static const sample = Key('pie_journey.chart');
}

/// Must match [ComminglePieChart]'s default animation duration.
const _animationDuration = Duration(milliseconds: 450);

/// Frames captured per expand/collapse animation (frame `000` .. `N-1`).
/// With a 450ms animation, 30 frames == a uniform 15ms per frame; the last
/// frame lands exactly on the settled resting state.
const _frameCount = 30;

// Half the production 320px chart so goldens are 160x160 (~1/4 the storage).
// Ring/badge/icon are scaled by the same 0.5 factor to stay proportional.
const _chartSize = 160.0;
const _badgeDiameter = 14.0;
const _ringThickness = 28.0;
const _ringPadding = 4.0;

// Drill indices into [_journeyData].
const _homeIndex = 1;
const _foodIndex = 0;
const _restaurantIndex = 0;
const _mcDonaldsIndex = 0;

void main() {
  final frameStep = Duration(
    microseconds: (_animationDuration.inMicroseconds / _frameCount).round(),
  );

  final controller = ComminglePieChartController();
  final slices = _journeyData;
  final food = slices[_foodIndex];
  final restaurant = food.slices[_restaurantIndex];
  final mcDonalds = restaurant.slices[_mcDonaldsIndex];
  final home = slices[_homeIndex];

  tapTest(
    'pie_journey',
    tapTestConfig(
      suite: 'pie_journey',
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

      // Home is a leaf: drill in and back out.
      await _captureExpand(
        tester: tester,
        controller: controller,
        key: home.key,
        label: '02_entering_home',
        expectedPathAtStart: [home.key],
        frameStep: frameStep,
      );
      await _captureCollapse(
        tester: tester,
        controller: controller,
        label: '03_leaving_home',
        expectedPathAtStart: const [],
        frameStep: frameStep,
      );

      // Food -> Restaurant -> McDonald's, then unwind level by level.
      await _captureExpand(
        tester: tester,
        controller: controller,
        key: food.key,
        label: '04_entering_food',
        expectedPathAtStart: [food.key],
        frameStep: frameStep,
      );
      await _captureExpand(
        tester: tester,
        controller: controller,
        key: restaurant.key,
        label: '05_entering_restaurant',
        expectedPathAtStart: [food.key, restaurant.key],
        frameStep: frameStep,
      );
      await _captureExpand(
        tester: tester,
        controller: controller,
        key: mcDonalds.key,
        label: '06_entering_mcdonalds',
        expectedPathAtStart: [food.key, restaurant.key, mcDonalds.key],
        frameStep: frameStep,
      );
      await _captureCollapse(
        tester: tester,
        controller: controller,
        label: '07_leaving_mcdonalds',
        expectedPathAtStart: [food.key, restaurant.key],
        frameStep: frameStep,
      );
      await _captureCollapse(
        tester: tester,
        controller: controller,
        label: '08_leaving_restaurant',
        expectedPathAtStart: [food.key],
        frameStep: frameStep,
      );
      await _captureCollapse(
        tester: tester,
        controller: controller,
        label: '09_leaving_food',
        expectedPathAtStart: const [],
        frameStep: frameStep,
      );
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

/// Drills into [key] and captures `${label}_000..N` across the animation.
Future<void> _captureExpand({
  required TapTester tester,
  required ComminglePieChartController controller,
  required ComminglePieSliceKey key,
  required String label,
  required List<ComminglePieSliceKey> expectedPathAtStart,
  required Duration frameStep,
}) async {
  await _capturePhase(
    tester: tester,
    controller: controller,
    action: () => controller.expand(key),
    label: label,
    expectedPathAtStart: expectedPathAtStart,
    frameStep: frameStep,
  );
}

/// Pops one level and captures `${label}_000..N` across the animation.
Future<void> _captureCollapse({
  required TapTester tester,
  required ComminglePieChartController controller,
  required String label,
  required List<ComminglePieSliceKey> expectedPathAtStart,
  required Duration frameStep,
}) async {
  await _capturePhase(
    tester: tester,
    controller: controller,
    action: controller.collapse,
    label: label,
    expectedPathAtStart: expectedPathAtStart,
    frameStep: frameStep,
  );
}

Future<void> _capturePhase({
  required TapTester tester,
  required ComminglePieChartController controller,
  required VoidCallback action,
  required String label,
  required List<ComminglePieSliceKey> expectedPathAtStart,
  required Duration frameStep,
}) async {
  // The path notification fires as soon as the transition starts.
  List<ComminglePieSliceKey>? pathFromListener;
  void onPath() {
    pathFromListener ??= List<ComminglePieSliceKey>.of(controller.path);
  }

  controller.addListener(onPath);
  action();
  await tester.widgetTester.pump();
  controller.removeListener(onPath);

  expect(controller.path, expectedPathAtStart);
  expect(pathFromListener, expectedPathAtStart);

  // Uniform steps across the animation: frame `i` lands at (i + 1) * frameStep,
  // so the final frame sits on the (essentially) settled resting level.
  for (var frame = 0; frame < _frameCount; frame++) {
    await tester.widgetTester.pump(frameStep);
    await _captureFrame(tester, label, frame);
  }

  // Guarantee the transition is fully committed before the next phase, so the
  // next expand/collapse is not rejected by the chart's "busy" guard.
  await tester.widgetTester.pumpAndSettle();
  expect(controller.path, expectedPathAtStart);
}

Future<void> _captureFrame(TapTester tester, String label, int index) async {
  final name = '${label}_${index.toString().padLeft(3, '0')}';
  await tester.snapshot(
    name,
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
              badgeDiameter: _badgeDiameter,
              ringThickness: _ringThickness,
              fullIconSweep: 0.4,
              minIconSweep: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Local copy of the demo data (copied from example/lib/pie_drill_demo_data.dart,
// intentionally self-contained so this test does not depend on the example).
// -----------------------------------------------------------------------------

List<ComminglePieSlice> get _journeyData => [
  _section(
    title: 'Food',
    value: 420 / 1751,
    color: const Color(0xFFE53935),
    icon: Icons.restaurant_rounded,
    slices: [
      _section(
        title: 'Restaurant',
        value: 0.65,
        color: const Color(0xFFB71C1C),
        icon: Icons.delivery_dining_rounded,
        slices: [
          _section(title: "McDonald's", value: 0.60, color: const Color(0xFF8B0000), icon: Icons.lunch_dining_rounded),
          _section(title: 'KFC', value: 0.40, color: const Color(0xFFFF5722), icon: Icons.fastfood_rounded),
        ],
      ),
      _section(title: 'Groceries', value: 0.20, color: const Color(0xFFFF1744), icon: Icons.shopping_basket_rounded),
      _section(title: 'Dessert', value: 0.10, color: const Color(0xFFFF8A80), icon: Icons.cake_rounded),
      _section(title: 'Coffee', value: 0.05, color: const Color(0xFFFFCDD2), icon: Icons.local_cafe_rounded),
    ],
  ),
  _section(title: 'Home', value: 680 / 1751, color: const Color(0xFF1E88E5), icon: Icons.home_rounded),
  _section(title: 'Transport', value: 185 / 1751, color: const Color(0xFF43A047), icon: Icons.directions_car_rounded),
  _section(title: 'Fun', value: 240 / 1751, color: const Color(0xFFFF9800), icon: Icons.celebration_rounded),
  _section(title: 'Health', value: 130 / 1751, color: const Color(0xFF8E24AA), icon: Icons.favorite_rounded),
  _section(title: 'Subscriptions', value: 96 / 1751, color: const Color(0xFF00ACC1), icon: Icons.subscriptions_rounded),
];

ComminglePieSlice _section({
  required String title,
  required double value,
  required Color color,
  required IconData icon,
  List<ComminglePieSlice> slices = const [],
}) {
  return ComminglePieSlice(
    key: title,
    value: value,
    color: color,
    slices: slices,
    iconBuilder: (context) => _badgeIcon(icon, color),
    titleBuilder: (context) => Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
    valueBuilder: (context) => Text(
      '${(value * 100).round()}%',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    ),
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
