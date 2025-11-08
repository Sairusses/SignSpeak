import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signspeak/pages/library-page.dart';
import 'package:signspeak/pages/settings-page.dart';
import 'package:signspeak/pages/sign-to-text-page.dart';
import 'package:signspeak/pages/text-to-sign-page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode themeMode;

  const Home({
    super.key,
    required this.onThemeChanged,
    required this.themeMode,
  });

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  int currentPageIndex = 0;
  late PageController _pageController;
  double _threshold = 0.05;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _pageController = PageController(initialPage: currentPageIndex);
    _loadThreshold();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _threshold = prefs.getDouble('threshold') ?? 0.05;
    });
  }
  Future<void> updateThreshold(double newThreshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('threshold', newThreshold);
    setState(() {
      _threshold = newThreshold;
    });
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
        children: [
          SignToTextPage(threshold: _threshold),
          const TextToSignPage(),
          const LibraryPage(),
          SettingsPage(
            initialThreshold: _threshold,
            onThresholdChanged: updateThreshold,
            isDarkMode: widget.themeMode == ThemeMode.dark,
            onThemeChanged: widget.onThemeChanged,
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                final bgColor = isDark
                    ? Colors.black.withOpacity(0.25)
                    : Colors.white.withOpacity(0.7);

                final borderColor = isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.4);

                final shadowColor = isDark
                    ? Colors.blueAccent.withOpacity(0.05)
                    : Colors.blueAccent.withOpacity(0.15);

                final selectedColor = isDark ? Colors.blueAccent : Colors.blueAccent;
                final unselectedColor = isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.6);

                return Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: borderColor,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: Colors.transparent,
                      indicatorColor: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.blueAccent.withOpacity(0.15),
                      labelTextStyle: MaterialStateProperty.all(
                        GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
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
                );
              },
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
