import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'pie_drill_demo_data.dart';

class PieScreen extends StatefulWidget {
  const PieScreen({super.key});

  @override
  State<PieScreen> createState() => _PieScreenState();
}

class _PieScreenState extends State<PieScreen> {
  final _chartController = ComminglePieChartController();

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: const FHeader(title: Text('ComminglePieChart')),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 8),
          Text(
            'Tap Food → Restaurant → McDonald\'s to drill in. '
            'Reset walks back one level at a time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ComminglePieChart(
                  slices: pieDrillDemoData,
                  controller: _chartController,
                  animationDuration: const Duration(milliseconds: 500),
                  animationCurve: Curves.easeInOut,
                  fullIconSweep: 0.4,
                  minIconSweep: 0.2,
                ),
                ListenableBuilder(
                  listenable: _chartController,
                  builder: (context, _) {
                    return _DemoChartHub(
                      onReset: _chartController.path.isNotEmpty ? _chartController.collapse : null,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _DemoChartHub extends StatelessWidget {
  final VoidCallback? onReset;

  const _DemoChartHub({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'July spending',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '100%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('← Reset'),
            ),
          ],
        ],
      ),
    );
  }
}
