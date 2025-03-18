import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../main_screens/translate_screen.dart';
import '../main_screens/home_screen.dart';
import '../main_screens/profile_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final PersistentTabController _controller = PersistentTabController(initialIndex: 0);
  late CameraController cameraController;
  bool _isCameraInitialized = false;

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: ('Home'),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary:  Theme.of(context).colorScheme.onPrimary,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.add),
        title: ('Translate'),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary:  Theme.of(context).colorScheme.onPrimary,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.person),
        title: ('Profile'),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary:  Theme.of(context).colorScheme.onPrimary,
      ),
    ];
  }
  List<Widget> _buildScreens() {
    return [
      HomeScreen(),
      TranslateScreen(cameraController: cameraController, isCameraInitialized: _isCameraInitialized),
      ProfileScreen(),
    ];
  }



  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        cameras[0], // Use the first available camera
        ResolutionPreset.medium,
      );

      await cameraController.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    }
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
