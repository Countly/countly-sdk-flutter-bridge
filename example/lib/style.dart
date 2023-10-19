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
  if (color == 'green') {
    return theColor['green'];
  } else if (color == 'teal') {
    return theColor['teal'];
  } else if (color == 'red') {
    return theColor['red'];
  } else if (color == 'brown') {
    return theColor['brown'];
  } else if (color == 'grey') {
    return theColor['grey'];
  } else if (color == 'blue') {
    return theColor['blue'];
  } else if (color == 'purple') {
    return theColor['purple'];
  } else if (color == 'violet') {
    return theColor['violet'];
  } else if (color == 'black') {
    return theColor['black'];
  } else if (color == 'olive') {
    return theColor['olive'];
  } else if (color == 'orange') {
    return theColor['orange'];
  } else if (color == 'yellow') {
    return theColor['yellow'];
  } else {
    return theColor['default'];
  }
}

TextStyle titleStyle() {
  return TextStyle(fontSize: 18, fontWeight: FontWeight.w900);
}

TextStyle subTitleStyle() {
  return TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}

// Theme that we use in the app
class AppTheme {
  static ThemeData countlyTheme() {
    return ThemeData(
      // This is the Countly green
      colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 44, 174, 92), brightness: Brightness.light),
      useMaterial3: true,
    );
  }
}
