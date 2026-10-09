import 'package:flutter/material.dart';

import '../models/expense.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF063F35);
  static const Color primary = Color(0xFF087F68);
  static const Color primaryLight = Color(0xFF2FA17E);

  static const Color background = Color(0xFFF8FBF8);
  static const Color cream = Color(0xFFF5F8F4);
  static const Color cardBackground = Colors.white;

  static const Color textDark = Color(0xFF173B45);
  static const Color textMuted = Color(0xFF6D858C);

  static const Color border = Color(0xFFDDE7E5);

  static const Color danger = Color(0xFFFF555C);
  static const Color warning = Color(0xFFE85D4E);

  /// Bundled font (see pubspec.yaml > flutter > fonts). Plus Jakarta Sans
  /// is used because it includes the peso sign (₱) and has clear,
  /// evenly spaced digits, which matters on a money app.
  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),

      fontFamily: fontFamily,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textDark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(14),
          ),
          side: BorderSide(
            color: border,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF9AA9A3),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: border,
            width: 1.2,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: border,
            width: 1.2,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,

          minimumSize: const Size(
            double.infinity,
            48,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,

          minimumSize: const Size(
            double.infinity,
            48,
          ),

          side: const BorderSide(
            color: border,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,

        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),

        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

final Map<ExpenseCategory, Color> categoryColors = {
  ExpenseCategory.food:
      const Color(0xFFFF5961),

  ExpenseCategory.transportation:
      const Color(0xFF4285F4),

  ExpenseCategory.load:
      const Color(0xFF9C4DFF),

  ExpenseCategory.supplies:
      const Color(0xFF9C4DFF),

  ExpenseCategory.savings:
      const Color(0xFFFFAB00),

  ExpenseCategory.misc:
      const Color(0xFFFFA900),
};