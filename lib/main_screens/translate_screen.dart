import 'package:flutter/material.dart';

class TranslateScreen extends StatelessWidget{
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Camera Screen", style: Theme.of(context).textTheme.bodyLarge,),
      ),
    );
  }

}