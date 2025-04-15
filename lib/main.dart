import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signspeak/themes/themes.dart';
import 'package:device_preview/device_preview.dart';

import 'home.dart';
import 'main_screens/home_screen.dart';

void main() {
  if(kDebugMode){
    runApp(
      DevicePreview(
        enabled: kDebugMode,
        builder: (context) => DevicePrev()
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSpeak',
      theme: MyThemes().lightTheme,
      darkTheme: MyThemes().darkTheme,
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class DevicePrev extends StatelessWidget {
  const DevicePrev({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightMode,
      builder: (context, nightMode, _){
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          title: 'SignSpeak',
          theme: MyThemes().lightTheme,
          darkTheme: MyThemes().darkTheme,
          themeMode: nightMode ? ThemeMode.dark : ThemeMode.light,
          home: Home(),
        );
      }
    );
  }
}
