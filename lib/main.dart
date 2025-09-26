import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: String.fromEnvironment("supabase_url"),
    anonKey: String.fromEnvironment("supabase_anon_key"),
  );
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
