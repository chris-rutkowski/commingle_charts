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
    return Scaffold(
      appBar: AppBar(title: const Text('Commingle Pie Chart')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Text(
            'Tap Food → Restaurant → McDonald\'s to drill in. '
            'Reset walks back one level at a time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            color: Colors.yellow,
            child: Padding(
              // reserves a space for pressedGrowth
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
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
                      pressedGrowth: 8.0,
                      pressGrowthAnimation: const CommingleChartsAnimation(
                        duration: Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                      ),
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
            ),
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: _chartController,
            builder: (context, _) {
              final path = _chartController.path;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FBreadcrumb(
                    children: [
                      const FBreadcrumbItem(child: Text('July spending')),
                      for (final (index, slice) in path.indexed)
                        FBreadcrumbItem(current: index == path.length - 1, child: slice.titleBuilder(context)),
                    ],
                  ),
                  if (path.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FButton(
                      variant: FButtonVariant.secondary,
                      mainAxisSize: MainAxisSize.min,
                      style: FButtonStyleDelta.delta(
                        tappableStyle: FTappableStyleDelta.delta(motion: FTappableMotion.none),
                      ),
                      onPress: _chartController.collapse,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              );
            },
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
          Text('July spending', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '100%',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
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
