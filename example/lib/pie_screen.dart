import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';
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
                      fullIconSweep: 0.4,
                      minIconSweep: 0.2,
                      pressedGrowth: 8.0,
                      pressGrowthAnimation: const CommingleChartsAnimation(
                        duration: Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                      ),
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
                        const FBreadcrumbItem(child: Text('July spending')),
                        for (final key in path)
                          if (_findSliceByKey(pieDrillDemoData, key) case final slice?)
                            FBreadcrumbItem(current: key == path.last, child: slice.titleBuilder(context)),
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

ComminglePieSlice? _findSliceByKey(List<ComminglePieSlice> slices, Object key) {
  for (final slice in slices) {
    if (slice.key == key) return slice;
    final found = _findSliceByKey(slice.slices, key);
    if (found != null) return found;
  }
  return null;
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
