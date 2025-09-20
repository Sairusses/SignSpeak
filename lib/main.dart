import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      enabled: kIsWeb,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSpeak',
      home: const Home(),
      theme: FlexThemeData.light(scheme: FlexScheme.shadBlue),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.shadBlue),
      themeMode: ThemeMode.light,
    );
  }
}
