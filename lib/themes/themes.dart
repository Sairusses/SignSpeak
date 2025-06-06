import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyThemes {

  //light theme colors
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color blueAccent = Colors.blueAccent;
  static const Color red = Colors.red;

  //dark theme colors
  static const Color dark = Color(0x33333333);
  static const Color grey = Color(0x8C8C8C8C);
  static const Color boneWhite = Color(0xFFF9F6EE);

  // Light Theme
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: black,
      scaffoldBackgroundColor: white,
      secondaryHeaderColor: black,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: blueAccent.withAlpha(102),
        cursorColor: blueAccent,
        selectionHandleColor: blueAccent,
      ),
      highlightColor: blueAccent,
      focusColor: blueAccent,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: black,
        onPrimary: white,
        secondary: white,
        onSecondary: black,
        error: red,
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
        indicatorShape: CircleBorder(),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: white);
          }
          return const IconThemeData(color: black);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
      primaryColor: boneWhite,
      scaffoldBackgroundColor: dark,
      secondaryHeaderColor: boneWhite,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: blueAccent.withAlpha(102),
        cursorColor: blueAccent,
        selectionHandleColor: blueAccent,
      ),
      highlightColor: blueAccent,
      focusColor: blueAccent,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: grey,
        onPrimary: boneWhite,
        secondary: dark,
        onSecondary: boneWhite,
        error: red,
        onError: black,
        surface: dark,
        onSurface: boneWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark,
        iconTheme: IconThemeData(color: boneWhite),
        titleTextStyle: TextStyle(
          color: boneWhite,
          fontSize: 20,
          fontFamily: GoogleFonts.roboto().fontFamily,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: boneWhite, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        titleMedium: TextStyle(color: boneWhite, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        titleSmall: TextStyle(color: boneWhite, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily),
        bodyLarge: TextStyle(color: boneWhite, fontSize: 20, fontFamily: GoogleFonts.roboto().fontFamily),
        bodyMedium: TextStyle(color: boneWhite, fontSize: 16, fontFamily: GoogleFonts.roboto().fontFamily),
        bodySmall: TextStyle(color: boneWhite, fontSize: 12, fontFamily: GoogleFonts.roboto().fontFamily),
      ),
      iconTheme: IconThemeData(color: boneWhite),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: grey,
          foregroundColor: boneWhite,
          textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark,
        indicatorColor: grey,
        indicatorShape: CircleBorder(),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: black);
          }
          return const IconThemeData(color: Colors.grey);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: boneWhite,
            fontSize: 12,
            fontFamily: GoogleFonts.roboto().fontFamily,
          ),
        ),
      )
    );
  }
}
