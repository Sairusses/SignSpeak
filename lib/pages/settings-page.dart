import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final double initialThreshold;
  final ValueChanged<double> onThresholdChanged;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.initialThreshold,
    required this.onThresholdChanged,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _currentThreshold;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _currentThreshold = widget.initialThreshold;
    _isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 40),
            Text(
              "Detection Sensitivity",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text( "Adjust how sensitive the system is when detecting sign changes. " "Lower = more strict, Higher = more tolerant.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Slider(
              value: _currentThreshold,
              min: 0.01,
              max: 0.20,
              divisions: 19,
              label: _currentThreshold.toStringAsFixed(2),
              onChanged: (value) {
                setState(() => _currentThreshold = value);
                widget.onThresholdChanged(value);
              },
            ),
            Text(
              "Current value: ${_currentThreshold.toStringAsFixed(2)}",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              "Appearance",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Toggle between light and dark themes"),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                widget.onThemeChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}