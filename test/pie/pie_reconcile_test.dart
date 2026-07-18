import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reordered-but-present chain keeps the user at the same node', (tester) async {
    final controller = ComminglePieChartController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(_initialData(), controller));

    // Drill Food -> Restaurant -> McDonald's.
    controller.expand(0);
    await tester.pumpAndSettle();
    controller.expand(0);
    await tester.pumpAndSettle();
    controller.expand(0);
    await tester.pumpAndSettle();

    expect(controller.path.map((s) => s.key).toList(), ['food', 'restaurant', 'mcdonalds']);

    // New data: same keys, reordered at multiple levels and with new values.
    await tester.pumpWidget(_host(_reorderedData(), controller));
    await tester.pump();

    // User stays at the same node; indices are remapped by key.
    expect(controller.path.map((s) => s.key).toList(), ['food', 'restaurant', 'mcdonalds']);
  });

  testWidgets('chain whose deep node is removed resets to the root', (tester) async {
    final controller = ComminglePieChartController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(_initialData(), controller));

    controller.expand(0);
    await tester.pumpAndSettle();
    controller.expand(0);
    await tester.pumpAndSettle();
    controller.expand(0);
    await tester.pumpAndSettle();

    expect(controller.path.map((s) => s.key).toList(), ['food', 'restaurant', 'mcdonalds']);

    // McDonald's is gone from Restaurant's children -> the chain is broken.
    await tester.pumpWidget(_host(_mcDonaldsRemovedData(), controller));
    await tester.pump();

    expect(controller.path, isEmpty);
  });

  testWidgets('top-level data swap while not drilled just applies', (tester) async {
    final controller = ComminglePieChartController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(_initialData(), controller));
    expect(controller.path, isEmpty);

    await tester.pumpWidget(_host(_reorderedData(), controller));
    await tester.pump();

    // Still at the top with no drill state, and no crash.
    expect(controller.path, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(List<ComminglePieSlice> slices, ComminglePieChartController controller) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: 320,
          child: ComminglePieChart(slices: slices, controller: controller),
        ),
      ),
    ),
  );
}

List<ComminglePieSlice> _initialData() => [
  _slice(
    key: 'food',
    value: 0.5,
    slices: [
      _slice(
        key: 'restaurant',
        value: 0.6,
        slices: [
          _slice(key: 'mcdonalds', value: 0.6),
          _slice(key: 'kfc', value: 0.4),
        ],
      ),
      _slice(key: 'groceries', value: 0.4),
    ],
  ),
  _slice(key: 'home', value: 0.5),
];

/// Same keys as [_initialData], reordered at every level with new values.
List<ComminglePieSlice> _reorderedData() => [
  _slice(key: 'home', value: 0.4),
  _slice(
    key: 'food',
    value: 0.6,
    slices: [
      _slice(key: 'groceries', value: 0.3),
      _slice(
        key: 'restaurant',
        value: 0.7,
        slices: [
          _slice(key: 'kfc', value: 0.5),
          _slice(key: 'mcdonalds', value: 0.5),
        ],
      ),
    ],
  ),
];

/// Like [_initialData] but McDonald's no longer exists under Restaurant.
List<ComminglePieSlice> _mcDonaldsRemovedData() => [
  _slice(
    key: 'food',
    value: 0.5,
    slices: [
      _slice(
        key: 'restaurant',
        value: 0.6,
        slices: [
          _slice(key: 'kfc', value: 1.0),
        ],
      ),
      _slice(key: 'groceries', value: 0.4),
    ],
  ),
  _slice(key: 'home', value: 0.5),
];

ComminglePieSlice _slice({
  required Object key,
  required double value,
  List<ComminglePieSlice> slices = const [],
}) {
  return ComminglePieSlice(
    key: key,
    value: value,
    color: const Color(0xFF000000),
    slices: slices,
    iconBuilder: (_) => const SizedBox.shrink(),
    titleBuilder: (_) => const SizedBox.shrink(),
    valueBuilder: (_) => const SizedBox.shrink(),
  );
}
