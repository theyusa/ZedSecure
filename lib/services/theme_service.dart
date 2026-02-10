import 'package:flutter/material.dart';
import 'package:zedsecure/services/mmkv_manager.dart';
import 'package:zedsecure/theme/app_theme.dart';

enum ThemeStyle {
  system,
  light,
  dark,
  amoled,
  midnight,
  deepBlue,
  emerald,
}

class ThemeService extends ChangeNotifier {
  ThemeStyle _themeStyle = ThemeStyle.system;

  ThemeStyle get themeStyle => _themeStyle;

  ThemeMode get themeMode {
    switch (_themeStyle) {
      case ThemeStyle.light:
        return ThemeMode.light;
      case ThemeStyle.system:
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  ThemeData getThemeData(BuildContext context) {
    final Brightness systemBrightness = MediaQuery.platformBrightnessOf(context);
    final bool isDark = _themeStyle == ThemeStyle.system 
        ? systemBrightness == Brightness.dark 
        : themeMode == ThemeMode.dark;

    switch (_themeStyle) {
      case ThemeStyle.light:
        return AppTheme.lightTheme();
      case ThemeStyle.dark:
        return AppTheme.darkTheme();
      case ThemeStyle.amoled:
        return AppTheme.amoledTheme();
      case ThemeStyle.midnight:
        return AppTheme.midnightTheme();
      case ThemeStyle.deepBlue:
        return AppTheme.deepBlueTheme();
      case ThemeStyle.emerald:
        return AppTheme.emeraldTheme();
      case ThemeStyle.system:
        return isDark ? AppTheme.darkTheme() : AppTheme.lightTheme();
    }
  }

  Future<void> _loadTheme() async {
    final styleStr = MmkvManager.decodeSettings('ui_theme_style', defaultValue: 'system');
    _themeStyle = _getThemeStyleFromString(styleStr ?? 'system');
    notifyListeners();
  }

  ThemeStyle _getThemeStyleFromString(String style) {
    return ThemeStyle.values.firstWhere(
      (e) => e.name == style,
      orElse: () => ThemeStyle.system,
    );
  }

  Future<void> setThemeStyle(ThemeStyle style) async {
    _themeStyle = style;
    MmkvManager.encodeSettings('ui_theme_style', style.name);
    notifyListeners();
  }

  // Deprecated: used for backward compatibility if needed
  Future<void> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        await setThemeStyle(ThemeStyle.light);
        break;
      case ThemeMode.dark:
        await setThemeStyle(ThemeStyle.dark);
        break;
      case ThemeMode.system:
        await setThemeStyle(ThemeStyle.system);
        break;
    }
  }

  Future<void> toggleTheme() async {
    if (_themeStyle == ThemeStyle.light) {
      await setThemeStyle(ThemeStyle.dark);
    } else if (_themeStyle == ThemeStyle.dark) {
      await setThemeStyle(ThemeStyle.amoled);
    } else {
      await setThemeStyle(ThemeStyle.light);
    }
  }
}
