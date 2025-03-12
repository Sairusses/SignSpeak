import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Themes Tester"),),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 100,),
            Text("This is a title text", style: Theme.of(context).textTheme.titleLarge,),
            SizedBox(height: 20,),
            Text("This is a body text", style: Theme.of(context).textTheme.bodyLarge,),
            ElevatedButton(onPressed: () {}, child: const Text('Elevated Button'),),

          ],
        ),
      ),
    );
  }
}