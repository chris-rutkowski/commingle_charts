import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ComminglePieChart renders', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ComminglePieChart(),
      ),
    );

    expect(find.byType(ComminglePieChart), findsOneWidget);
  });
}
