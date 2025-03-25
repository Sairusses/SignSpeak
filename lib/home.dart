import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../main_screens/interaction_screen.dart';
import '../main_screens/home_screen.dart';
import '../main_screens/profile_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: 'Home',
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).colorScheme.onPrimary,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.front_hand),
        title: 'Translate',
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).colorScheme.onPrimary,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: 'Profile',
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).colorScheme.onPrimary,
      ),
    ];
  }

  List<Widget> _buildScreens() {
    return const [
      HomeScreen(),
      InteractionScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineToSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      navBarStyle: NavBarStyle.style3,
    );
  }
}
