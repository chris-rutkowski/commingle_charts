import 'package:commingle_charts/commingle_charts.dart';
import 'package:flutter/material.dart';

const pieDrillDemoFoodIndex = 0;
const pieDrillDemoHouseIndex = 1;
const pieDrillDemoMovieIndex = 5;
const pieDrillDemoRestaurantIndex = 0;
const pieDrillDemoMcDonaldsIndex = 0;

/// Flat top-level demo data with Food child categories.
List<ComminglePieSlice> get pieDrillDemoData => [
  _section(
    title: 'Food',
    value: 420 / 1751,
    color: const Color(0xFFE53935),
    icon: Icons.restaurant_rounded,
    slices: [
      _section(
        title: 'Restaurant',
        value: 0.65,
        color: const Color(0xFFB71C1C),
        icon: Icons.delivery_dining_rounded,
        slices: [
          _section(title: "McDonald's", value: 0.60, color: const Color(0xFF8B0000), icon: Icons.lunch_dining_rounded),
          _section(title: 'KFC', value: 0.40, color: const Color(0xFFFF5722), icon: Icons.fastfood_rounded),
        ],
      ),
      _section(title: 'Groceries', value: 0.20, color: const Color(0xFFFF1744), icon: Icons.shopping_basket_rounded),
      _section(title: 'Dessert', value: 0.10, color: const Color(0xFFFF8A80), icon: Icons.cake_rounded),
      _section(title: 'Coffee', value: 0.05, color: const Color(0xFFFFCDD2), icon: Icons.local_cafe_rounded),
    ],
  ),
  _section(title: 'Home', value: 680 / 1751, color: const Color(0xFF1E88E5), icon: Icons.home_rounded),
  _section(title: 'Transport', value: 185 / 1751, color: const Color(0xFF43A047), icon: Icons.directions_car_rounded),
  _section(title: 'Fun', value: 240 / 1751, color: const Color(0xFFFF9800), icon: Icons.celebration_rounded),
  _section(title: 'Health', value: 130 / 1751, color: const Color(0xFF8E24AA), icon: Icons.favorite_rounded),
  _section(title: 'Subscriptions', value: 96 / 1751, color: const Color(0xFF00ACC1), icon: Icons.subscriptions_rounded),
];

ComminglePieSlice _section({
  required String title,
  required double value,
  required Color color,
  required IconData icon,
  List<ComminglePieSlice> slices = const [],
}) {
  return ComminglePieSlice(
    value: value,
    color: color,
    slices: slices,
    iconBuilder: (context) => _badgeIcon(icon, color),
    titleBuilder: (context) => Text(title, textAlign: .center, style: Theme.of(context).textTheme.titleSmall),
    valueBuilder: (context) => Text(
      '${(value * 100).round()}%',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    ),
  );
}

Widget _badgeIcon(IconData icon, Color color) {
  return Container(
    width: awesomePieChartDefaultBadgeDiameter,
    height: awesomePieChartDefaultBadgeDiameter,
    decoration: BoxDecoration(
      shape: .circle,
      color: color,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Icon(icon, size: 15, color: Colors.white),
  );
}
