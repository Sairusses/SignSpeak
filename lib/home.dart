import 'package:flutter/material.dart';
import 'package:signspeak/main_screens/interaction_screen.dart';
import 'package:signspeak/main_screens/profile_screen.dart';

import 'main_screens/home_screen.dart';
import 'main_screens/library_screen.dart';

class Home extends StatefulWidget{
  const Home({super.key});
  @override
  State<Home> createState() => HomeState();
}
class HomeState extends State<Home>{
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          height: MediaQuery.of(context).size.height * 0.05,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home, color: Colors.white,),
              icon: Icon(Icons.home_outlined, color: Colors.black),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: Colors.white),
              icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.black),
              label: 'Interact',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.bookmark_rounded, color: Colors.white),
              icon: Icon(Icons.bookmark_outline_rounded, color: Colors.black),
              label: 'Library',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.person, color: Colors.white),
              icon: Icon(Icons.person_outline, color: Colors.black),
              label: 'Profile',
            ),
          ]
      ),
      body: <Widget>[
        const HomeScreen(),
        const InteractionScreen(),
        const LibraryScreen(),
        const ProfileScreen(),
      ][currentPageIndex],
    );
  }

}