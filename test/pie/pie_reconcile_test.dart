import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptest/taptest.dart';

import '../snapshots/_utils/tap_test_config.dart';

/// Exercises drill-path reconciliation when [ComminglePieChart.slices] changes
/// from the outside. Every edge case is asserted by logic (the controller's
/// drill path) and, where it is visually meaningful, captured as a snapshot.
abstract final class _Keys {
  static const sample = Key('pie_reconcile.chart');
}

const _chartSize = 320.0;
const _ringPadding = 8.0;

// Drill indices into [_journeyData].
const _foodIndex = 0;
const _restaurantIndex = 0;
const _mcDonaldsIndex = 0;

/// Drives the live [slices] passed to the chart so the test can swap data from
/// the outside, exactly like a real app pushing new data.
final ValueNotifier<List<ComminglePieSlice>> _data = ValueNotifier(_journeyData);

void main() {
  final controller = ComminglePieChartController();

  tapTest(
    'pie_reconcile',
    tapTestConfig(
      suite: 'pie_reconcile',
      snapshot: const SnapshotConfig(path: 'goldens/[suite]/[name].png'),
      home: _ChartHost(
        size: _chartSize,
        controller: controller,
      ),
    ),
    (tester) async {
      timeDilation = 1.0;
      await _prepareView(tester);

      // -- Case B (valid): drilled in, chain survives a data change. ----------
      await _resetTo(tester, controller, _journeyData);
      await _drill(tester, controller, [_foodIndex, _restaurantIndex]);
      expect(controller.path, ['Food', 'Restaurant']);
      await tester.snapshot('01_restaurant_before', key: _Keys.sample, variations: false);

      // New data: same keys, reordered at every level with new values. The user
      // stays inside Restaurant; the level just snaps to the new proportions.
      await _swap(tester, _reorderedData);
      expect(controller.path, ['Food', 'Restaurant']);
      await tester.snapshot('02_restaurant_after_reorder', key: _Keys.sample, variations: false);

      // -- Case B (broken): drilled deep, leaf disappears -> reset to root. ----
      await _resetTo(tester, controller, _journeyData);
      await _drill(tester, controller, [_foodIndex, _restaurantIndex, _mcDonaldsIndex]);
      expect(controller.path, ['Food', 'Restaurant', "McDonald's"]);
      await tester.snapshot('03_mcdonalds_before', key: _Keys.sample, variations: false);

      // McDonald's no longer exists under Restaurant: the user is kicked out.
      await _swap(tester, _mcDonaldsRemovedData);
      expect(controller.path, isEmpty);
      await tester.snapshot('04_mcdonalds_after_reset', key: _Keys.sample, variations: false);

      // -- Case A: top view, data simply applies. -----------------------------
      await _resetTo(tester, controller, _journeyData);
      await tester.snapshot('05_top_before', key: _Keys.sample, variations: false);

      await _swap(tester, _reorderedData);
      expect(controller.path, isEmpty);
      await tester.snapshot('06_top_after', key: _Keys.sample, variations: false);

      // -- Extra logic-only edge cases (no distinct visuals to capture). -------

      // A shallow ancestor disappearing also breaks the chain and resets. Here
      // the whole "Food" branch is gone while the user is deep inside it.
      await _resetTo(tester, controller, _journeyData);
      await _drill(tester, controller, [_foodIndex, _restaurantIndex]);
      expect(controller.path, ['Food', 'Restaurant']);
      await _swap(tester, _foodRemovedData);
      expect(controller.path, isEmpty);

      // A valid parent whose drilled child survives keeps the user in place even
      // when a *sibling* of that child is removed (KFC gone, McDonald's stays).
      await _resetTo(tester, controller, _journeyData);
      await _drill(tester, controller, [_foodIndex, _restaurantIndex, _mcDonaldsIndex]);
      expect(controller.path, ['Food', 'Restaurant', "McDonald's"]);
      await _swap(tester, _kfcRemovedData);
      expect(controller.path, ['Food', 'Restaurant', "McDonald's"]);
    },
  );
}

/// Clears any drill state and installs [slices] as the current data.
Future<void> _resetTo(
  TapTester tester,
  ComminglePieChartController controller,
  List<ComminglePieSlice> slices,
) async {
  controller.reset();
  _data.value = slices;
  await tester.widgetTester.pumpAndSettle();
}

/// Expands each index in [path] in turn (resolving the key at each level),
/// settling between steps.
Future<void> _drill(
  TapTester tester,
  ComminglePieChartController controller,
  List<int> path,
) async {
  var slices = _data.value;
  for (final index in path) {
    controller.expand(slices[index].key);
    await tester.widgetTester.pumpAndSettle();
    slices = slices[index].slices;
  }
}

/// Pushes [slices] from the outside and settles (no animation on reconcile).
Future<void> _swap(TapTester tester, List<ComminglePieSlice> slices) async {
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
// Self-contained data. All variants share keys (titles) with [_journeyData] so
// reconciliation can match surviving nodes by key.
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

/// Same keys as [_journeyData], reordered at every level with new values.
List<ComminglePieSlice> get _reorderedData => [
  _section(title: 'Home', value: 520 / 1751, color: const Color(0xFF1E88E5), icon: Icons.home_rounded),
  _section(
    title: 'Food',
    value: 560 / 1751,
    color: const Color(0xFFE53935),
    icon: Icons.restaurant_rounded,
    slices: [
      _section(title: 'Coffee', value: 0.10, color: const Color(0xFFFFCDD2), icon: Icons.local_cafe_rounded),
      _section(title: 'Groceries', value: 0.25, color: const Color(0xFFFF1744), icon: Icons.shopping_basket_rounded),
      _section(
        title: 'Restaurant',
        value: 0.55,
        color: const Color(0xFFB71C1C),
        icon: Icons.delivery_dining_rounded,
        slices: [
          _section(title: 'KFC', value: 0.55, color: const Color(0xFFFF5722), icon: Icons.fastfood_rounded),
          _section(title: "McDonald's", value: 0.45, color: const Color(0xFF8B0000), icon: Icons.lunch_dining_rounded),
        ],
      ),
      _section(title: 'Dessert', value: 0.10, color: const Color(0xFFFF8A80), icon: Icons.cake_rounded),
    ],
  ),
  _section(title: 'Subscriptions', value: 120 / 1751, color: const Color(0xFF00ACC1), icon: Icons.subscriptions_rounded),
  _section(title: 'Fun', value: 200 / 1751, color: const Color(0xFFFF9800), icon: Icons.celebration_rounded),
  _section(title: 'Transport', value: 210 / 1751, color: const Color(0xFF43A047), icon: Icons.directions_car_rounded),
  _section(title: 'Health', value: 141 / 1751, color: const Color(0xFF8E24AA), icon: Icons.favorite_rounded),
];

/// Like [_journeyData] but McDonald's no longer exists under Restaurant.
List<ComminglePieSlice> get _mcDonaldsRemovedData => [
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
          _section(title: 'KFC', value: 1.0, color: const Color(0xFFFF5722), icon: Icons.fastfood_rounded),
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

/// Like [_journeyData] but the whole Food branch is gone (shallow break).
List<ComminglePieSlice> get _foodRemovedData => [
  _section(title: 'Home', value: 680 / 1751, color: const Color(0xFF1E88E5), icon: Icons.home_rounded),
  _section(title: 'Transport', value: 185 / 1751, color: const Color(0xFF43A047), icon: Icons.directions_car_rounded),
  _section(title: 'Fun', value: 240 / 1751, color: const Color(0xFFFF9800), icon: Icons.celebration_rounded),
  _section(title: 'Health', value: 130 / 1751, color: const Color(0xFF8E24AA), icon: Icons.favorite_rounded),
  _section(title: 'Subscriptions', value: 96 / 1751, color: const Color(0xFF00ACC1), icon: Icons.subscriptions_rounded),
];

/// Like [_journeyData] but KFC (a sibling of the drilled McDonald's) is gone.
List<ComminglePieSlice> get _kfcRemovedData => [
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
          _section(title: "McDonald's", value: 1.0, color: const Color(0xFF8B0000), icon: Icons.lunch_dining_rounded),
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
