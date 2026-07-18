import 'package:big_decimal/big_decimal.dart';
import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';

import 'financial_fragment.dart';

/// Real July spending amounts as a [FinancialFragment] tree (total 1751).
final _financialData = <FinancialFragment>[
  FinancialFragment(
    id: 'id_food',
    value: BigDecimal.parse('420'),
    title: 'Food',
    color: const Color(0xFFE53935),
    icon: Icons.restaurant_rounded,
    children: [
      FinancialFragment(
        id: 'id_restaurant',
        value: BigDecimal.parse('273'),
        title: 'Restaurant',
        color: const Color(0xFFB71C1C),
        icon: Icons.delivery_dining_rounded,
        children: [
          FinancialFragment(
            id: 'id_mcdonalds',
            value: BigDecimal.parse('163.80'),
            title: "McDonald's",
            color: const Color(0xFF8B0000),
            icon: Icons.lunch_dining_rounded,
          ),
          FinancialFragment(
            id: 'id_kfc',
            value: BigDecimal.parse('109.20'),
            title: 'KFC',
            color: const Color(0xFFFF5722),
            icon: Icons.fastfood_rounded,
          ),
        ],
      ),
      FinancialFragment(
        id: 'id_groceries',
        value: BigDecimal.parse('84'),
        title: 'Groceries',
        color: const Color(0xFFFF1744),
        icon: Icons.shopping_basket_rounded,
      ),
      FinancialFragment(
        id: 'id_dessert',
        value: BigDecimal.parse('42'),
        title: 'Dessert',
        color: const Color(0xFFFF8A80),
        icon: Icons.cake_rounded,
      ),
      FinancialFragment(
        id: 'id_coffee',
        value: BigDecimal.parse('21'),
        title: 'Coffee',
        color: const Color(0xFFFFCDD2),
        icon: Icons.local_cafe_rounded,
      ),
    ],
  ),
  FinancialFragment(
    id: 'id_home',
    value: BigDecimal.parse('680'),
    title: 'Home',
    color: const Color(0xFF1E88E5),
    icon: Icons.home_rounded,
  ),
  FinancialFragment(
    id: 'id_transport',
    value: BigDecimal.parse('185'),
    title: 'Transport',
    color: const Color(0xFF43A047),
    icon: Icons.directions_car_rounded,
  ),
  FinancialFragment(
    id: 'id_fun',
    value: BigDecimal.parse('240'),
    title: 'Fun',
    color: const Color(0xFFFF9800),
    icon: Icons.celebration_rounded,
  ),
  FinancialFragment(
    id: 'id_health',
    value: BigDecimal.parse('130'),
    title: 'Health',
    color: const Color(0xFF8E24AA),
    icon: Icons.favorite_rounded,
  ),
  FinancialFragment(
    id: 'id_subscriptions',
    value: BigDecimal.parse('96'),
    title: 'Subscriptions',
    color: const Color(0xFF00ACC1),
    icon: Icons.subscriptions_rounded,
  ),
  // Redundant zero-amount category: proves buildPieSlices omits non-positive
  // fragments (this never appears as a slice).
  FinancialFragment(
    id: 'id_savings',
    value: BigDecimal.zero,
    title: 'Savings',
    color: const Color(0xFF6D4C41),
    icon: Icons.savings_rounded,
  ),
];

/// Synthetic top-most node: the whole chart aggregated as "July spending".
final _root = FinancialFragment(
  id: 'id_root',
  value: _financialData.fold(BigDecimal.zero, (sum, f) => sum + f.value),
  title: 'July spending',
  color: const Color(0xFF212121),
  icon: Icons.pie_chart_rounded,
  children: _financialData,
);

/// Demo data for the pie chart, sorted largest-first at every level.
List<ComminglePieSlice> get pieDrillDemoData => buildPieSlices(_financialData);

/// Resolves the drill [path] to a [FinancialFragment].
///
/// An empty path returns the top-most node ([_root]); otherwise it walks the
/// children by key, one level per entry.
FinancialFragment financialFragmentForPath(List<ComminglePieSliceKey> path) {
  var node = _root;
  for (final key in path) {
    node = node.children.firstWhere((child) => child.id == key, orElse: () => node);
  }
  return node;
}
