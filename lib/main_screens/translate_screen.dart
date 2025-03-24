import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  TranslateScreenState createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SignSpeak'),
        centerTitle: true,
        leading: IconButton(onPressed: (){}, icon: Icon(Icons.flash_on)),
        actions: [
          IconButton(onPressed: (){}, icon: Icon(Icons.settings))
        ],
      ),
      body: Column(
        children: [

        ],
      ),
    );
  }
}