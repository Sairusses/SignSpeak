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
              selectedIcon: Icon(Icons.home,),
              icon: Icon(Icons.home_outlined,),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Interact',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.bookmark_rounded, ),
              icon: Icon(Icons.bookmark_outline_rounded, ),
              label: 'Library',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.person,),
              icon: Icon(Icons.person_outline,),
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