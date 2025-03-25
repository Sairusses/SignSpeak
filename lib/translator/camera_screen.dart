import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = AwesomeTheme(
      bottomActionsBackgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
      buttonTheme: AwesomeButtonTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconSize: 20,
        foregroundColor: Theme.of(context).colorScheme.secondary,
        padding: const EdgeInsets.all(16),
        buttonBuilder: (child, onTap) {
          return ClipOval(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                splashColor: Theme.of(context).colorScheme.primary,
                highlightColor: Colors.cyan.withValues(alpha: 0.5),
                onTap: onTap,
                child: child,
              ),
            ),
          );
        },
      ),
    );
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
      saveConfig: SaveConfig.photoAndVideo(),
      theme: theme,
    ));
  }
}
