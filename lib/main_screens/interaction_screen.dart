import 'package:flutter/material.dart';

import '../translator/camera_screen.dart';

class InteractionScreen extends StatefulWidget {
  const InteractionScreen({super.key});

  @override
  InteractionScreenState createState() => InteractionScreenState();
}

class InteractionScreenState extends State<InteractionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SignSpeak'),
        centerTitle: true,
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.flash_on)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CameraScreen()),
            );
          },
          child: const Text('Camera Screen'),
        ),
      ),
    );
  }
}
