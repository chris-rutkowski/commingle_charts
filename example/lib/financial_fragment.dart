import 'package:big_decimal/big_decimal.dart';
import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';

/// A node in the financial hierarchy holding a real decimal [value].
///
/// [value] is the absolute amount (e.g. `163.80`), not a share. Shares for the
/// pie chart are derived in [buildPieSlices].
final class FinancialFragment {
  /// Stable, unique identifier for this fragment.
  final String id;

  /// Absolute amount for this fragment.
  final BigDecimal value;

  final String title;
  final Color color;
  final IconData icon;

  /// Child fragments; empty means a leaf.
  final List<FinancialFragment> children;

  const FinancialFragment({
    required this.id,
    required this.value,
    required this.title,
    required this.color,
    required this.icon,
    this.children = const [],
  });
}

/// Builds pie slices from [fragments], largest first, recursing into children.
///
/// [ComminglePieSlice.value] is a share of its parent, so each fragment's
/// amount is divided by the sum of its level (which equals its parent amount).
///
/// Only fragments with a positive amount are mapped; zero (or negative) amounts
/// are omitted, since [ComminglePieSlice.value] must be `> 0`.
List<ComminglePieSlice> buildPieSlices(List<FinancialFragment> fragments) {
  final positive = [for (final f in fragments) if (f.value.compareTo(BigDecimal.zero) > 0) f];
  final total = positive.fold(BigDecimal.zero, (sum, f) => sum + f.value);
  final sorted = [...positive]..sort((a, b) => b.value.compareTo(a.value));

  return [
    for (final fragment in sorted)
      ComminglePieSlice(
        key: fragment.id,
        value: fragment.value.divide(total, roundingMode: RoundingMode.HALF_UP, scale: 12).toDouble(),
        color: fragment.color,
        slices: buildPieSlices(fragment.children),
        iconBuilder: (context) => _badgeIcon(fragment.icon, fragment.color),
        titleBuilder: (context) =>
            Text(fragment.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
        valueBuilder: (context) => Text(
          formatCurrency(fragment.value),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
  ];
}

/// Formats an absolute [value] as a currency string (e.g. `$163.80`).
String formatCurrency(BigDecimal value) {
  return '\$${value.withScale(2, roundingMode: RoundingMode.HALF_UP).toPlainString()}';
}

Widget _badgeIcon(IconData icon, Color color) {
  return Container(
    width: 28.0,
    height: 28.0,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Icon(icon, size: 15, color: Colors.white),
  );
}
