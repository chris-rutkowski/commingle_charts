import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'pie_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: const FHeader(title: Text('CommingleCharts')),
      child: Column(
        children: [
          FTileGroup(
            children: [
              FTile(
                suffix: const Icon(FLucideIcons.chevronRight),
                title: const Text('ComminglePieChart'),
                onPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PieScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
