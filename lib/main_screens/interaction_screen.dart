import 'package:flutter/material.dart';

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
        child: const Text(' Camera Screen'),
      ),
    );
  }
}
