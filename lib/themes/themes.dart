import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyThemes {
  // Common colors
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color selectionColor = Colors.blueAccent;
  static const Color errorColor = Colors.red;

  // Light Theme
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: black,
      scaffoldBackgroundColor: white,
      secondaryHeaderColor: black,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: selectionColor.withAlpha(102),
        cursorColor: selectionColor,
        selectionHandleColor: selectionColor,
      ),
      highlightColor: selectionColor,
      focusColor: selectionColor,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: black,
        onPrimary: white,
        secondary: white,
        onSecondary: black,
        error: errorColor,
        onError: white,
        surface: white,
        onSurface: black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        iconTheme: IconThemeData(color: black),
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 20,
          fontFamily: GoogleFonts.roboto().fontFamily,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: black, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        titleMedium: TextStyle(color: black, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        titleSmall: TextStyle(color: black, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        bodyLarge: TextStyle(color: black, fontSize: 20, fontFamily: GoogleFonts.roboto().fontFamily),
        bodyMedium: TextStyle(color: black, fontSize: 16, fontFamily: GoogleFonts.roboto().fontFamily),
        bodySmall: TextStyle(color: black, fontSize: 12, fontFamily: GoogleFonts.roboto().fontFamily),
      ),
      iconTheme: IconThemeData(color: black),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        indicatorColor: black,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: black,
            fontSize: 12,
            fontFamily: GoogleFonts.roboto().fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Dark Theme
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: white,
      scaffoldBackgroundColor: black,
      secondaryHeaderColor: white,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: selectionColor.withAlpha(102),
        cursorColor: selectionColor,
        selectionHandleColor: selectionColor,
      ),
      highlightColor: selectionColor,
      focusColor: selectionColor,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: white,
        onPrimary: black,
        secondary: black,
        onSecondary: white,
        error: errorColor,
        onError: black,
        surface: black,
        onSurface: white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: black,
        iconTheme: IconThemeData(color: white),
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontFamily: GoogleFonts.roboto().fontFamily,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        titleMedium: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        titleSmall: TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        bodyLarge: TextStyle(color: white, fontSize: 20, fontFamily: GoogleFonts.roboto().fontFamily),
        bodyMedium: TextStyle(color: white, fontSize: 16, fontFamily: GoogleFonts.roboto().fontFamily),
        bodySmall: TextStyle(color: white, fontSize: 12, fontFamily: GoogleFonts.roboto().fontFamily),
      ),
      iconTheme: IconThemeData(color: white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: black,
        selectedItemColor: white,
        unselectedItemColor: Colors.grey.shade700,
      ),
    );
  }
}
