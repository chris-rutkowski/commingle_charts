import 'package:flutter/material.dart';
import 'package:taptest/taptest.dart';

/// Minimal themed [Config] for `commingle_charts` snapshot tests.
///
/// Deliberately font-agnostic (no [CustomFont]s) — text rendering is out of
/// scope for these goldens.
Config tapTestConfig({
  required Widget home,
  String? suite,
  double pixelDensity = 1,
  Size screenSize = const Size(393, 852),
  SnapshotConfig snapshot = const SnapshotConfig(path: 'goldens/[test]/[name].png'),
}) {
  return Config(
    suite: suite,
    pixelDensity: pixelDensity,
    screenSize: screenSize,
    themeModes: const [ThemeMode.light],
    snapshot: snapshot,
    builder: (params) {
      return ListenableBuilder(
        listenable: Listenable.merge([params.themeMode, params.locale]),
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: params.themeMode.value,
            theme: ThemeData.light(),
            home: home,
          );
        },
      );
    },
  );
}
