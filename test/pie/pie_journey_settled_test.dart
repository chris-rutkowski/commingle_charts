import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptest/taptest.dart';

import '../snapshots/_utils/tap_test_config.dart';

abstract final class _Keys {
  static const sample = Key('pie_journey_settled.chart');
}

const _chartSize = 320.0;
const _ringPadding = 8.0;

// Drill indices into [_journeyData].
const _homeIndex = 1;
const _foodIndex = 0;
const _restaurantIndex = 0;
const _mcDonaldsIndex = 0;

void main() {
  final controller = ComminglePieChartController();
  final slices = _journeyData;
  final food = slices[_foodIndex];
  final restaurant = food.slices[_restaurantIndex];
  final mcDonalds = restaurant.slices[_mcDonaldsIndex];
  final home = slices[_homeIndex];

  tapTest(
    'pie_journey_settled',
    tapTestConfig(
      suite: 'pie_journey_settled',
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
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: () => controller.expand(home.key),
        label: '02_home',
        expectedPath: [home.key],
      );
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: controller.collapse,
        label: '03_top',
        expectedPath: const [],
      );

      // Food -> Restaurant -> McDonald's, then unwind level by level.
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: () => controller.expand(food.key),
        label: '04_food',
        expectedPath: [food.key],
      );
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: () => controller.expand(restaurant.key),
        label: '05_restaurant',
        expectedPath: [food.key, restaurant.key],
      );
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: () => controller.expand(mcDonalds.key),
        label: '06_mcdonalds',
        expectedPath: [food.key, restaurant.key, mcDonalds.key],
      );
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: controller.collapse,
        label: '07_restaurant',
        expectedPath: [food.key, restaurant.key],
      );
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: controller.collapse,
        label: '08_food',
        expectedPath: [food.key],
      );
      await _captureSettled(
        tester: tester,
        controller: controller,
        action: controller.collapse,
        label: '09_top',
        expectedPath: const [],
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

/// Fires [action], settles the transition in one shot, and snapshots the
/// resting level. No per-frame capture — `pumpAndSettle` fast-forwards the
/// animation straight to its committed state.
Future<void> _captureSettled({
  required TapTester tester,
  required ComminglePieChartController controller,
  required VoidCallback action,
  required String label,
  required List<ComminglePieSliceKey> expectedPath,
}) async {
  action();
  await tester.widgetTester.pumpAndSettle();
  expect(controller.path, expectedPath);
  await tester.snapshot(label, key: _Keys.sample, variations: false);
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
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SizedBox.square(
          dimension: size,
          child: RepaintBoundary(
            key: _Keys.sample,
            child: Padding(
              padding: const EdgeInsets.all(_ringPadding),
              child: ComminglePieChart(
                slices: slices,
                controller: controller,
                fullIconSweep: 0.4,
                minIconSweep: 0.2,
              ),
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
  );
}

Widget _badgeIcon(IconData icon, Color color) {
  return Container(
    width: 28.0,
    height: 28.0,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Icon(icon, size: 15, color: Colors.white),
  );
}
