import 'package:flutter/material.dart';

class ThemeManager with ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();

  factory ThemeManager() {
    return instance;
  }

  ThemeManager._internal();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
