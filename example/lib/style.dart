import 'package:flutter/material.dart';

// Colors that we use in the app
Map<String, Map<String, Color>> theColor = {
  'default': {'button': const Color(0xffe0e0e0), 'text': const Color(0xff000000)},
  'red': {'button': const Color(0xffdb2828), 'text': const Color(0xffffffff)},
  'green': {'button': Color.fromARGB(255, 44, 174, 92), 'text': const Color(0xffffffff)},
  'teal': {'button': const Color(0xff00b5ad), 'text': const Color(0xff000000)},
  'blue': {'button': const Color(0xff54c8ff), 'text': const Color(0xff000000)},
  'grey': {'button': const Color(0xff767676), 'text': const Color(0xffffffff)},
  'brown': {'button': const Color(0xffa5673f), 'text': const Color(0xff000000)},
  'purple': {'button': const Color(0xffa333c8), 'text': const Color(0xffffffff)},
  'violet': {'button': Color.fromARGB(255, 112, 71, 202), 'text': const Color(0xffffffff)},
  'yellow': {'button': const Color(0xfffbbd08), 'text': const Color(0xffffffff)},
  'black': {'button': const Color(0xff1b1c1d), 'text': const Color(0xffffffff)},
  'olive': {'button': const Color(0xffd9e778), 'text': const Color(0xff000000)},
  'orange': {'button': const Color(0xffff851b), 'text': const Color(0xff000000)}
};

// Helper function to get the color
Map<String, Color>? getColor(color) {
  return theColor[color] ?? theColor['default'];
}

TextStyle titleStyle() {
  return TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
}

TextStyle subTitleStyle() {
  return TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff666666));
}

// Theme that we use in the app
class AppTheme {
  static const Color _countlyGreen = Color.fromARGB(255, 44, 174, 92);

  static ThemeData countlyTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _countlyGreen,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
