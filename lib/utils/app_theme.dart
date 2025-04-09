import 'package:flutter/material.dart';

class AppTheme {
  // App colors
  static const Color primaryColor = Color(0xFF5E17EB);
  static const Color secondaryColor = Color(0xFF00C6AE);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color lightGrayColor = Color(0xFFF5F5F5);
  
  // Text styles with fallback fonts
  static TextStyle get headingLarge => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle get headingMedium => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle get headingSmall => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textColor,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textColor,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textColor,
  );
  
  // Create theme data
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
    );
  }
}
