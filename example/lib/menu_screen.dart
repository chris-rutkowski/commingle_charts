import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'pie_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commingle Charts')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FTileGroup(
            children: [
              FTile(
                suffix: const Icon(FLucideIcons.chevronRight),
                title: const Text('Commingle Pie Chart'),
                onPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PieScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
