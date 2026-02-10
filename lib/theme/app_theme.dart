import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class AppTheme {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color connectedGreen = Color(0xFF34C759);
  static const Color disconnectedRed = Color(0xFFFF3B30);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  // Additional Accent Colors
  static const Color primaryIndigo = Color(0xFF5856D6);
  static const Color primaryPurple = Color(0xFFAF52DE);
  static const Color primaryPink = Color(0xFFFF2D55);
  static const Color primaryOrange = Color(0xFFFF9500);
  static const Color primaryGreen = Color(0xFF28CD41);
  static const Color primaryTeal = Color(0xFF5AC8FA);

  static ThemeData lightTheme({Color accentColor = primaryBlue}) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: systemGray6,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
      ),
    );
  }

  static ThemeData darkTheme({Color accentColor = primaryBlue, Color? backgroundColor}) {
    final bg = backgroundColor ?? const Color(0xFF121212);
    
    // Modern Dark Gradient Background simulation via scaffoldBackgroundColor
    // Note: For proper gradient, a Container with gradient decoration would be needed in widget tree
    // Here we use a deep, modern dark grey-blue color
    
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: _getSurfaceColorForBackground(bg),
      ),
    );
  }

  static Color _getSurfaceColorForBackground(Color bg) {
    // Pure AMOLED: Use distinct dark grey for cards
    if (bg == Colors.black) {
      return const Color(0xFF1C1C1E);
    }
    // Modern Dark (#121212): Use lighter grey for cards to create contrast
    if (bg.value == const Color(0xFF121212).value) {
      return const Color(0xFF282828);
    }
    // Other themes: Use slightly transparent version
    return bg.withOpacity(0.8);
  }

  static ThemeData amoledTheme({Color accentColor = primaryBlue}) {
    return darkTheme(accentColor: accentColor, backgroundColor: Colors.black);
  }

  static ThemeData midnightTheme() {
    return darkTheme(accentColor: primaryPurple, backgroundColor: const Color(0xFF120E16));
  }

  static ThemeData deepBlueTheme() {
    return darkTheme(accentColor: primaryBlue, backgroundColor: const Color(0xFF0F172A));
  }

  static ThemeData emeraldTheme() {
    return darkTheme(accentColor: primaryGreen, backgroundColor: const Color(0xFF064E3B));
  }

  static BoxDecoration glassDecoration({
    double borderRadius = 16,
    bool isDark = true,
  }) {
    return futuristicGlassDecoration(borderRadius: borderRadius, isDark: isDark);
  }

  static BoxDecoration futuristicGlassDecoration({
    double borderRadius = 24,
    bool isDark = true,
    Color? glowColor,
    BuildContext? context,
  }) {
    final bgColor = context != null 
        ? Theme.of(context).scaffoldBackgroundColor 
        : (isDark ? Colors.black : systemGray6);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: isDark 
          ? Colors.white.withOpacity(0.08)
          : Colors.white.withOpacity(0.85),
      border: Border.all(
        color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.08),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration futuristicButtonDecoration({
    required bool isPrimary,
    bool isDestructive = false,
    bool isDark = true,
  }) {
    final baseColor = isPrimary
        ? (isDestructive ? disconnectedRed : primaryBlue)
        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05));

    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: baseColor,
      boxShadow: isPrimary && isDark ? [
        BoxShadow(
          color: (isDestructive ? disconnectedRed : primaryBlue).withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        )
      ] : [],
    );
  }

  static BoxDecoration iosCardDecoration({bool isDark = true, BuildContext? context}) {
    final Color bgColor;
    final Color? borderColor;
    final List<BoxShadow>? shadows;

    if (context != null) {
      final theme = Theme.of(context);
      final isAmoled = theme.scaffoldBackgroundColor == Colors.black;
      
      if (isAmoled) {
        // Pure AMOLED: Use distinct dark grey and subtle border for visibility
        bgColor = const Color(0xFF1C1C1E);
        borderColor = Colors.white.withOpacity(0.08);
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        // Modern Dark, Midnight, Emerald, etc.: Use theme surface color
        bgColor = theme.colorScheme.surface;
        if (isDark) {
           // Dark themes get subtle shadow and border
           shadows = [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 12,
               offset: const Offset(0, 4),
             ),
           ];
           borderColor = Colors.white.withOpacity(0.05);
        }
      }
    } else {
      // Fallback for cases without context
      bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: bgColor,
      border: borderColor != null
          ? Border.all(color: borderColor!, width: 0.5)
          : null,
      boxShadow: shadows,
    );
  }

  static BoxDecoration dynamicIslandDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(44),
      color: Colors.black,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    );
  }

  static Color getPingColor(int? ping) {
    if (ping == null || ping < 0) return systemGray;
    if (ping < 100) return connectedGreen;
    if (ping < 300) return warningOrange;
    return disconnectedRed;
  }

  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.7),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
