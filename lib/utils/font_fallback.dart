import 'package:flutter/material.dart';

/// This class provides fallback fonts in case the custom fonts fail to load
class FontFallback {
  static const String primaryFont = 'Poppins';
  static const String fallbackFont = 'Roboto'; // System font that's usually available
  
  // Method to get a font family with fallback
  static String get fontFamily => primaryFont;
  
  // Method to create a TextStyle with fallback fonts
  static TextStyle createTextStyle({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      fontFamilyFallback: [fallbackFont, 'sans-serif'],
    );
  }
}
