import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'financial_fragment.dart';
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

  /// The library emits no haptics; the app owns all feedback. Fire a light tap
  /// then run [action].
  void _lightTap(VoidCallback action) {
    HapticFeedback.lightImpact();
    action();
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
                      animation: const CommingleChartsAnimation(
                        duration: Duration(milliseconds: 450),
                        curve: Curves.easeInOut,
                      ),
                      ringThickness: 64.0,
                      fullIconSweep: 0.4,
                      minIconSweep: 0.2,
                      pressedGrowth: 8.0,
                      pressGrowthAnimation: const CommingleChartsAnimation(
                        duration: Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                      ),
                      onSlicePressed: (_) => HapticFeedback.lightImpact(),
                    ),
                    _DemoChartHub(controller: _chartController),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FBreadcrumb(
                      children: [
                        FBreadcrumbItem(
                          current: path.isEmpty,
                          onPress: path.isEmpty ? null : () => _lightTap(_chartController.collapseToRoot),
                          child: const Text('July spending'),
                        ),
                        for (final key in path)
                          FBreadcrumbItem(
                            current: key == path.last,
                            onPress: key == path.last ? null : () => _lightTap(() => _chartController.collapseTo(key)),
                            child: Text(
                              financialFragmentForPath([...path.takeWhile((k) => k != key), key]).title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (path.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FButton(
                      variant: FButtonVariant.secondary,
                      mainAxisSize: MainAxisSize.min,
                      style: FButtonStyleDelta.delta(
                        tappableStyle: FTappableStyleDelta.delta(motion: FTappableMotion.none),
                      ),
                      onPress: () => _lightTap(_chartController.collapse),
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
  final ComminglePieChartController controller;

  const _DemoChartHub({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final fragment = financialFragmentForPath(controller.path);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fragment.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                formatCurrency(fragment.value),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
