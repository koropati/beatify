import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1DB954), // Spotify-like green
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF282828),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1DB954),
      secondary: Color(0xFF1DB954),
      surface: Color(0xFF282828),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF1DB954),
      inactiveTrackColor: Colors.grey[800],
      thumbColor: Colors.white,
    ),
  );
}
