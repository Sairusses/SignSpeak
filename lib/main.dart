import 'package:flutter/material.dart';
import 'package:signspeak/themes/themes.dart';
import 'package:device_preview/device_preview.dart';

import 'home.dart';

void main() {
  bool isPreview = true;
  // ignore: dead_code
  if(isPreview){
    runApp(
      DevicePreview(
          builder: (context) => DevicePrev()
      ),
    );
  }
  // ignore: dead_code
  else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme Tester',
      theme: MyThemes().lightTheme,
      darkTheme: MyThemes().darkTheme,
      home: Home(),
    );
  }
}

class DevicePrev extends StatelessWidget {
  const DevicePrev({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Theme Tester',
      theme: MyThemes().darkTheme,
      darkTheme: MyThemes().darkTheme,
      home: Home(),
    );
  }
}
