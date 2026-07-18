import 'package:flutter/foundation.dart';

import 'commingle_pie_slice.dart';

/// Imperative actions and drill-path notifications for a ComminglePieChart.
final class ComminglePieChartController extends ChangeNotifier {
  VoidCallback? _reset;
  VoidCallback? _collapse;
  void Function(int index)? _expand;

  List<ComminglePieSlice> _path = const [];

  /// Drill path from the root. Empty at the top level / after [reset].
  ///
  /// Updates as soon as an expand or collapse animation starts, so listeners
  /// see e.g. `[Food]` immediately on tap, not only when the transition ends.
  List<ComminglePieSlice> get path => _path;

  /// Instantly clears expansion (no collapse animation).
  void reset() => _reset?.call();

  /// Animates one level back (or reverses an in-flight transition).
  void collapse() => _collapse?.call();

  /// Expands the section at [index] of the current level (same as tapping that arc).
  void expand(int index) => _expand?.call(index);

  /// Pushed by the chart when the effective drill path changes.
  void updatePath(List<ComminglePieSlice> next) {
    if (listEquals(_path, next)) return;
    _path = List<ComminglePieSlice>.unmodifiable(next);
    notifyListeners();
  }

  void attach({
    required VoidCallback reset,
    required VoidCallback collapse,
    required void Function(int index) expand,
  }) {
    _reset = reset;
    _collapse = collapse;
    _expand = expand;
  }

  void detach({
    required VoidCallback reset,
    required VoidCallback collapse,
    required void Function(int index) expand,
  }) {
    if (_reset == reset) _reset = null;
    if (_collapse == collapse) _collapse = null;
    if (_expand == expand) _expand = null;
    updatePath(const []);
  }
}
