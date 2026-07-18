import 'package:flutter/material.dart';

/// Stable identity for a [ComminglePieSlice], unique among its siblings.
typedef ComminglePieSliceKey = String;

/// One slice. [value] is this slice’s share of its **parent** (0–1).
/// Nested [slices] are shares of **this** slice, recursively.
final class ComminglePieSlice {
  /// Stable identity for this slice, unique among its siblings.
  ///
  /// Used to preserve the user's drill position when the chart's data changes:
  /// the drilled chain is matched by key, so slices may be reordered or have
  /// their values updated without kicking the user out of the current level.
  final ComminglePieSliceKey key;

  final WidgetBuilder iconBuilder;

  /// Share of the parent chart / parent slice (e.g. `0.6` = 60%).
  ///
  /// Must be **positive** (`> 0`). The magnitude is otherwise arbitrary: it does
  /// not need to be a fraction or sum to any particular total. Sibling values are
  /// summed and each slice is displayed proportionally to its share of that sum.
  ///
  /// Zero or negative values are unsupported — they break the proportional
  /// geometry (and a level summing to zero divides by zero) — so they are
  /// rejected by an assertion in debug builds. Omit such entries when building
  /// your slice list instead.
  final double value;

  /// Solid fill for the slice (needed to paint the ring).
  final Color color;

  /// Child slices; empty means a leaf.
  final List<ComminglePieSlice> slices;

  const ComminglePieSlice({
    required this.key,
    required this.iconBuilder,
    required this.value,
    required this.color,
    this.slices = const [],
  }) : assert(value > 0, 'ComminglePieSlice.value must be positive (got $value).');

  bool get hasChildren => slices.isNotEmpty;

  double get childrenTotalValue => slices.fold<double>(0, (sum, slice) => sum + slice.value);
}
