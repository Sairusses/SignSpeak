import 'package:flutter/material.dart';

import 'custom_widgets/bottom_nav_bar.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Themes Tester"),),
      body: BottomNavBar()
    );
  }
}