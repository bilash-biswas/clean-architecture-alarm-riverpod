import 'package:flutter/material.dart';

class AppTheme {
  // Ultra Dark Premium Theme (AMOLED Black base)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF070708),
      primaryColor: const Color(0xFF8A2BE2), // Electric Purple
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9D4EDD), // Bright Neon Purple
        secondary: Color(0xFF240046), // Dark Indigo
        tertiary: Color(0xFF00F5D4), // Cyan Accent
        surface: Color(0xFF121214), // Glassy dark surface
        error: Color(0xFFFF0055), // Neon Pink/Red for errors/active alarms
        onPrimary: Colors.white,
        onSecondary: Colors.white70,
        onSurface: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w200,
          color: Colors.white,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xE6FFFFFF),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E24).withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
    );
  }

  // Soft Glassy Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      primaryColor: const Color(0xFF7B2CBF), // Deep Purple
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF7B2CBF),
        secondary: Color(0xFFE0AAFF),
        tertiary: Color(0xFF00BBF9),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFFF0055),
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w200,
          color: Color(0xFF101012),
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Color(0xFF101012),
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF101012),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xE6000000),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black54,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
        ),
      ),
    );
  }

  // Neon gradients for custom components
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD), Color(0xFFE0AAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFF00F5D4), Color(0xFF00BBF9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient activeAlarmGradient = LinearGradient(
    colors: [Color(0xFFFF0055), Color(0xFFFF5E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0C), Color(0xFF140C20), Color(0xFF0A0A0C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient lightBackgroundGradient = LinearGradient(
    colors: [Color(0xFFF5F3FF), Color(0xFFFFF0F5), Color(0xFFE0F2FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static Gradient getBackgroundGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundGradient
        : lightBackgroundGradient;
  }

  // Glassmorphic Decoration helper
  static BoxDecoration glassDecoration({
    double blur = 20,
    double opacity = 0.08,
    BorderRadiusGeometry? borderRadius,
    bool isDark = true,
  }) {
    final color = isDark ? Colors.white : Colors.black;
    return BoxDecoration(
      color: color.withOpacity(isDark ? opacity : 0.04),
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      border: Border.all(
        color: color.withOpacity(isDark ? opacity * 1.5 : 0.08),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
