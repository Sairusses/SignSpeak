import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyThemes {
  final Color whiteTextColor = Color(0xffEEEEEE);
  // Dark Theme
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xff00ADB5),
      scaffoldBackgroundColor: Color(0xff222831),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xff393E46),
        titleTextStyle: TextStyle(color: whiteTextColor, fontSize: 20, fontFamily: GoogleFonts.roboto().fontFamily,),
        iconTheme: IconThemeData(color: Color(0xffEEEEEE)),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: whiteTextColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily,),
        titleMedium: TextStyle(color: whiteTextColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily,),
        titleSmall: TextStyle(color: whiteTextColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.roboto().fontFamily,),
        bodyLarge: TextStyle(color: whiteTextColor, fontSize: 20, fontFamily: GoogleFonts.roboto().fontFamily,),
        bodyMedium: TextStyle(color: whiteTextColor, fontSize: 16, fontFamily: GoogleFonts.roboto().fontFamily,),
        bodySmall: TextStyle(color: whiteTextColor, fontSize: 12, fontFamily: GoogleFonts.roboto().fontFamily,),
      ),
      iconTheme: IconThemeData(color: Color(0xff00ADB5)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff00ADB5),
          foregroundColor: Color(0xff222831),
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

  // Light Theme
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xff3F72AF),
      scaffoldBackgroundColor: Color(0xffF9F7F7),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xffDBE2EF),
        titleTextStyle: TextStyle(color: Color(0xff112D4E), fontSize: 20),
        iconTheme: IconThemeData(color: Color(0xff112D4E)),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Color(0xff112D4E)),
        bodyMedium: TextStyle(color: Color(0xff112D4E)),
      ),
      iconTheme: IconThemeData(color: Color(0xff3F72AF)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff3F72AF),
          foregroundColor: Color(0xffF9F7F7),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xffDBE2EF),
        selectedItemColor: Color(0xff112D4E),
        unselectedItemColor: Color(0xff3F72AF),
      ),
    );
  }
}