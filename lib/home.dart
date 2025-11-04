import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() => currentPageIndex = index);
  }

  void onDestinationSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    setState(() => currentPageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Colors.blueAccent;
    final Color unselectedColor = Colors.grey.shade500;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 45),
            const SizedBox(width: 8),
            Text(
              "SignSpeak",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),

      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: onPageChanged,
        children: const [
          SignToTextPage(),
          TextToSignPage(),
          LibraryPage(),
          SettingsPage(title: 'Generate GIFs'),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: Colors.transparent,
                  indicatorColor: Colors.blueAccent.withOpacity(0.15),
                  labelTextStyle: MaterialStateProperty.all(
                    GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: NavigationBar(
                  height: 70,
                  elevation: 0,
                  selectedIndex: currentPageIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    _buildDestination(
                      icon: CupertinoIcons.camera_circle,
                      selectedIcon: CupertinoIcons.camera_circle_fill,
                      label: 'Sign to Text',
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                      isSelected: currentPageIndex == 0,
                    ),
                    _buildDestination(
                      icon: Icons.transcribe_outlined,
                      selectedIcon: Icons.transcribe,
                      label: 'Text to Sign',
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                      isSelected: currentPageIndex == 1,
                    ),
                    _buildDestination(
                      icon: CupertinoIcons.book,
                      selectedIcon: CupertinoIcons.book_fill,
                      label: 'Library',
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                      isSelected: currentPageIndex == 2,
                    ),
                    _buildDestination(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                      isSelected: currentPageIndex == 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required Color selectedColor,
    required Color unselectedColor,
    required bool isSelected,
  }) {
    return NavigationDestination(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          isSelected ? selectedIcon : icon,
          key: ValueKey(isSelected),
          color: isSelected ? selectedColor : unselectedColor,
          size: 28,
        ),
      ),
      label: label,
    );
  }
}
