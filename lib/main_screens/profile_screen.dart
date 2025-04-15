import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<bool> isNightMode = ValueNotifier(false);

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getBool('isNightMode') ?? false;
  isNightMode.value = savedTheme;
}

Future<void> saveThemePreference(bool isNight) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isNightMode', isNight);
}

class ProfileScreen extends StatelessWidget{
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightMode,
      builder: (context, nightMode, _) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final newTheme = !nightMode;
              isNightMode.value = newTheme;
              saveThemePreference(newTheme); // Save preference
            },
            child: Icon(
              nightMode ? Icons.wb_sunny : Icons.nightlight_round,
            ),
          ),
          body: Center(
            child: Text(
              "Home Screen",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}