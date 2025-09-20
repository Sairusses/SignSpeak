import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SignToTextPage extends StatefulWidget{
  const SignToTextPage({super.key});

  @override
  State<StatefulWidget> createState() => SignToTextPageState();

}

class SignToTextPageState extends State<SignToTextPage> with SingleTickerProviderStateMixin{
  late final TabController _controller;

  @override
  void initState() {
    _controller = TabController(length: 2, vsync: this);
    super.initState();
  }

  Widget realTime() {
    return Container(
      child: Text("Real Time")
    );
  }
  Widget runTime() {
    return Container(
        child: Text("Run Time")
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          children: [
            Text("Sign Language Translation", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Translate sign language to text in real-time or after recording", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey,)),
            const Gap(20),
          ],
        ),
      )
    );
  }
}