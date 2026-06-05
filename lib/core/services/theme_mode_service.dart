import 'package:flutter/material.dart';

/// Holds the user-selected theme mode.
///
/// In debug builds this is toggled from the AppBar.
/// In release builds it will be settable from the Profile screen.
class ThemeModeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Whether the app is currently rendering in dark mode.
  ///
  /// Resolves [ThemeMode.system] against the platform brightness so the
  /// toggle icon and direction are correct when the user's system is in dark
  /// mode but no explicit preference has been set yet.
  bool get isDark {
    if (_mode == ThemeMode.dark) return true;
    if (_mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
