import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signspeak/main_screens/interaction_screen.dart';
import 'package:signspeak/main_screens/profile_screen.dart';
import 'main_screens/home_screen.dart';
import 'main_screens/library_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  int currentPageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  void onDestinationSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(milliseconds: 700),
        onDestinationSelected: onDestinationSelected,
        height: MediaQuery.of(context).size.height * 0.1,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(CupertinoIcons.chat_bubble_fill),
            icon: Icon(CupertinoIcons.chat_bubble),
            label: 'Interact',
          ),
          NavigationDestination(
            selectedIcon: Icon(CupertinoIcons.book_fill),
            icon: Icon(CupertinoIcons.book),
            label: 'Library',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: onPageChanged,
        children: const [
          HomeScreen(),
          InteractionScreen(),
          LibraryScreen(),
          ProfileScreen(),
        ],
      ),
    );
  }
}
