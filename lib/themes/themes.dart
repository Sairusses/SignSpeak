import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyThemes {


  // Dark Theme
  ThemeData get darkTheme {
    final Color primaryColor = Color(0xff00ADB5);
    final Color secondaryColor = Color(0xff393E46);
    final Color surfaceColor = Color(0xff222831);
    final Color errorColor = Colors.red.shade700;
    final Color onColor = Color(0xffEEEEEE);
    return ThemeData(
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: primaryColor.withAlpha(102),
        cursorColor: primaryColor,
        selectionHandleColor: primaryColor,
      ),
      highlightColor: primaryColor,
      focusColor: primaryColor,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: primaryColor,
          onPrimary: onColor,
          secondary: secondaryColor,
          onSecondary: onColor,
          error: errorColor,
          onError: onColor,
          surface: surfaceColor,
          onSurface: onColor
      ),
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xff393E46),
        titleTextStyle: TextStyle(color: onColor, fontSize: 20, fontFamily: GoogleFonts.roboto().fontFamily,),
        iconTheme: IconThemeData(color: onColor),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: onColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily,),
        titleMedium: TextStyle(color: onColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily,),
        titleSmall: TextStyle(color: onColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily,),
        bodyLarge: TextStyle(color: onColor, fontSize: 20, fontFamily: GoogleFonts.roboto().fontFamily,),
        bodyMedium: TextStyle(color: onColor, fontSize: 16, fontFamily: GoogleFonts.roboto().fontFamily,),
        bodySmall: TextStyle(color: onColor, fontSize: 12, fontFamily: GoogleFonts.roboto().fontFamily,),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: surfaceColor,
          textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xff393E46),
        selectedItemColor: Color(0xff00ADB5),
        unselectedItemColor: Color(0xffEEEEEE),
      ),
    );
  }

}