import 'package:flutter/foundation.dart';

import 'commingle_pie_slice.dart';

/// Imperative actions and drill-path notifications for a ComminglePieChart.
final class ComminglePieChartController extends ChangeNotifier {
  VoidCallback? _reset;
  VoidCallback? _collapse;
  void Function(ComminglePieSliceKey key)? _expand;

  List<ComminglePieSliceKey> _path = const [];

  /// Drill path from the root as slice keys. Empty at the top level / after
  /// [reset].
  ///
  /// Updates as soon as an expand or collapse animation starts, so listeners
  /// see e.g. `[Food]` immediately on tap, not only when the transition ends.
  List<ComminglePieSliceKey> get path => _path;

  /// Instantly clears expansion (no collapse animation).
  void reset() => _reset?.call();

  /// Animates one level back (or reverses an in-flight transition).
  void collapse() => _collapse?.call();

  /// Expands the section with [key] in the current level (same as tapping that
  /// arc). No-op if no section at the current level has that key.
  void expand(ComminglePieSliceKey key) => _expand?.call(key);

  /// Pushed by the chart when the effective drill path changes.
  @internal
  void updatePath(List<ComminglePieSliceKey> next) {
    if (listEquals(_path, next)) return;
    _path = List<ComminglePieSliceKey>.unmodifiable(next);
    notifyListeners();
  }

  @internal
  void attach({
    required VoidCallback reset,
    required VoidCallback collapse,
    required void Function(ComminglePieSliceKey key) expand,
  }) {
    _reset = reset;
    _collapse = collapse;
    _expand = expand;
  }

  @internal
  void detach({
    required VoidCallback reset,
    required VoidCallback collapse,
    required void Function(ComminglePieSliceKey key) expand,
  }) {
    if (_reset == reset) _reset = null;
    if (_collapse == collapse) _collapse = null;
    if (_expand == expand) _expand = null;
    updatePath(const []);
  }
}
