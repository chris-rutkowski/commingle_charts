import 'package:flutter/material.dart';
import 'package:taptest/taptest.dart';

import '../snapshots/_utils/tap_test_config.dart';

abstract final class _Keys {
  static const sample = Key('yellow_square.sample');
}

void main() {
  tapTest(
    'yellow_square',
    tapTestConfig(
      home: const _YellowSquareSample(),
    ),
    (tester) async {
      await tester.widgetTester.pumpAndSettle();
      await tester.snapshot('yellow_square', key: _Keys.sample);
    },
  );
}

/// A 50×50 yellow square padded 16 on every edge (82×82 total).
final class _YellowSquareSample extends StatelessWidget {
  const _YellowSquareSample();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: _Keys.sample,
        child: const ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(width: 50, height: 50, child: ColoredBox(color: Colors.yellow)),
          ),
        ),
      ),
    );
  }
}
