import 'package:flutter/material.dart';

typedef AwesomePieChartWidgetBuilder = Widget Function(BuildContext context);

/// One slice. [value] is this slice’s share of its **parent** (0–1).
/// Nested [slices] are shares of **this** slice, recursively.
final class ComminglePieSlice {
  final AwesomePieChartWidgetBuilder iconBuilder;
  final AwesomePieChartWidgetBuilder titleBuilder;
  final AwesomePieChartWidgetBuilder valueBuilder;

  /// Share of the parent chart / parent slice (e.g. `0.6` = 60%).
  final double value;

  /// Solid fill for the slice (needed to paint the ring).
  final Color color;

  /// Child slices; empty means a leaf.
  final List<ComminglePieSlice> slices;

  const ComminglePieSlice({
    required this.iconBuilder,
    required this.titleBuilder,
    required this.valueBuilder,
    required this.value,
    required this.color,
    this.slices = const [],
  });

  bool get hasChildren => slices.isNotEmpty;

  double get childrenTotalValue => slices.fold<double>(0, (sum, slice) => sum + slice.value);
}
