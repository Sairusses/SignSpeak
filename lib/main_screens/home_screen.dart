import 'package:flutter/material.dart';

final ValueNotifier<bool> isNightMode = ValueNotifier(false);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isNightMode,
      builder: (context, nightMode, _) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              isNightMode.value = !nightMode; // Toggle theme
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