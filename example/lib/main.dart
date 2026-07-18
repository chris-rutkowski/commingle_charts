import 'package:example/pie_screen.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FThemes.zinc.light.touch;

    return MaterialApp(
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      theme: theme.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(data: theme, child: child!),
      // home: const MenuScreen(), // let's have menu once we have more than one demo
      home: const PieScreen(),
    );
  }
}
