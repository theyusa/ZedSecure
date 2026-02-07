import 'package:flutter/material.dart';
import 'package:zedsecure/services/mmkv_manager.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final uiModeNight = MmkvManager.decodeSettings('ui_mode_night', defaultValue: 'auto');
    _themeMode = _getThemeModeFromString(uiModeNight ?? 'auto');
    notifyListeners();
  }

  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'auto':
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
      default:
        return 'auto';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    MmkvManager.encodeSettings('ui_mode_night', _getStringFromThemeMode(mode));
    notifyListeners();
  }

  Future<void> setThemeModeFromString(String mode) async {
    await setThemeMode(_getThemeModeFromString(mode));
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
