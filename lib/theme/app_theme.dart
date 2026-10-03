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

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),

      fontFamily: 'Arial',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textDark,
        centerTitle: false,
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
            fontWeight: FontWeight.w800,
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
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),

        unselectedLabelStyle: TextStyle(
          fontSize: 10,
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