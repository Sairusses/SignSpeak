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
        centerTitle: false,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CameraScreen()),
            );
          },
          child: const Text('Camera Screen'),
        ),
      ),
    );
  }
}
