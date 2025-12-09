import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF1F7A8C);
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      selectedIconTheme: IconThemeData(size: 22),
      unselectedIconTheme: IconThemeData(size: 20),
    ),
    cardTheme: CardThemeData(
      surfaceTintColor: base.colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
