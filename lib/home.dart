import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signspeak/pages/library-page.dart';

import 'package:signspeak/pages/settings-page.dart';
import 'package:signspeak/pages/sign-to-text-page.dart';
import 'package:signspeak/pages/text-to-sign-page.dart';


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
      appBar: AppBar(
        title: const Text(
          "SignSpeak",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        scrolledUnderElevation: 0,
        leading: Image.asset('assets/logo.png'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.3),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 2.0,
        animationDuration: const Duration(milliseconds: 300),
        onDestinationSelected: onDestinationSelected,
        height: MediaQuery.of(context).size.height * 0.1,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(CupertinoIcons.camera_circle_fill, color: Colors.blue,),
            icon: Icon(CupertinoIcons.camera_circle),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.transcribe, color: Colors.blue,),
            icon: Icon(Icons.transcribe_outlined),
            label: 'Text to Sign',
          ),
          NavigationDestination(
            selectedIcon: Icon(CupertinoIcons.book_fill, color: Colors.blue,),
            icon: Icon(CupertinoIcons.book),
            label: 'Text to Sign',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings, color: Colors.blue,),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
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
          LibraryPage(),
          SettingsPage(title: 'Generate Gifs',),
        ],
      ),
    );
  }
}