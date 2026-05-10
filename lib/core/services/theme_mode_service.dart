import 'package:flutter/material.dart';

/// Holds the user-selected theme mode.
///
/// In debug builds this is toggled from the AppBar.
/// In release builds it will be settable from the Profile screen.
class ThemeModeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
