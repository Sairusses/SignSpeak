import 'package:camera/camera.dart';
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
  final ScrollController scrollController = ScrollController();

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: ('Home'),
        scrollController: scrollController,
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary:  Theme.of(context).colorScheme.onPrimary,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.front_hand),
        title: ('Translate'),
        scrollController: scrollController,
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary:  Theme.of(context).colorScheme.onPrimary,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.person),
        title: ('Profile'),
        scrollController: scrollController,
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary:  Theme.of(context).colorScheme.onPrimary,
      ),
    ];
  }
  List<Widget> _buildScreens() {
    return [
      HomeScreen(),
      InteractionScreen(),
      ProfileScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
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
