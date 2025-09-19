import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signspeak/pages/profile-page.dart';
import 'package:signspeak/pages/sign-to-text-page.dart';
import 'package:signspeak/pages/text-to-sign-page.dart';
import 'package:signspeak/pages/upload-page.dart';

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
    requestPermissions();
    _pageController = PageController(initialPage: currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
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
        backgroundColor: Colors.white,
        elevation: 2.0,
        animationDuration: const Duration(milliseconds: 300),
        onDestinationSelected: onDestinationSelected,
        height: MediaQuery.of(context).size.height * 0.1,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(CupertinoIcons.camera_circle_fill),
            icon: Icon(CupertinoIcons.camera_circle),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.text_format),
            icon: Icon(Icons.text_format_outlined),
            label: 'Text to Sign',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.file_upload),
            icon: Icon(Icons.file_upload_outlined),
            label: 'Upload',
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
          SignToTextPage(),
          TextToSignPage(),
          UploadPage(),
          ProfilePage(),
        ],
      ),
    );
  }
}