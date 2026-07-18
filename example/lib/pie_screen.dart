import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class PieScreen extends StatelessWidget {
  const PieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FScaffold(
      header: FHeader(title: Text('ComminglePieChart')),
      child: Center(child: ComminglePieChart()),
    );
  }
}
