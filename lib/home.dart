import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signspeak/pages/awareness-page.dart';
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

  // KIDS THEME: Define a fun palette for each tab
  final List<Color> _tabColors = [
    const Color(0xFFFF9F1C), // Orange (Sign to Text)
    const Color(0xFF2EC4B6), // Teal/Blue (Text to Sign)
    const Color(0xFFCBF3F0), // Soft Green (Library - background logic)
    const Color(0xFFFFBF69), // Soft Pink/Peach (Awareness)
  ];

  // Helper to get active color based on index
  Color get _activeColor {
    switch (currentPageIndex) {
      case 0: return const Color(0xFFFF9F1C); // Orange
      case 1: return const Color(0xFF4361EE); // Blue
      case 2: return const Color(0xFF4CC9F0); // Light Blue
      case 3: return const Color(0xFFF72585); // Pink
      default: return const Color(0xFF4361EE);
    }
  }

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
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut, // Bouncy animation for kids!
    );
    setState(() => currentPageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    // KIDS THEME: Background colors shouldn't be stark black/white
    final scaffoldBg = isDark ? const Color(0xFF2D1B4E) : const Color(0xFFFFFDF5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _activeColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _activeColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Assuming you have an asset, otherwise use an Icon for testing
              Image.asset('assets/logo.png', height: 35),
              const SizedBox(width: 10),
              Text(
                "SignSpeak",
                style: GoogleFonts.fredoka( // Bubbly font
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
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
          const AwarenessPage(),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 10),
        child: Container(
          decoration: BoxDecoration(
            // Solid candy color background instead of glass
            color: isDark ? const Color(0xFF483D8B) : Colors.white,
            borderRadius: BorderRadius.circular(40), // Pill shape
            border: Border.all(
              color: _activeColor, // Border changes color based on tab
              width: 3.0, // Chunky border
            ),
            boxShadow: [
              BoxShadow(
                color: _activeColor.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                indicatorColor: _activeColor.withOpacity(0.2),
                labelTextStyle: MaterialStateProperty.all(
                  GoogleFonts.fredoka( // Matching bubbly font
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              child: NavigationBar(
                height: 75,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedIndex: currentPageIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: [
                  _buildKidsDestination(
                    icon: CupertinoIcons.camera_fill,
                    label: 'Scan',
                    color: const Color(0xFFFF9F1C), // Orange
                    index: 0,
                  ),
                  _buildKidsDestination(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Speak',
                    color: const Color(0xFF4361EE), // Blue
                    index: 1,
                  ),
                  _buildKidsDestination(
                    icon: CupertinoIcons.book_fill,
                    label: 'Learn',
                    color: const Color(0xFF4CC9F0), // Cyan
                    index: 2,
                  ),
                  _buildKidsDestination(
                    icon: Icons.emoji_objects_rounded,
                    label: 'Fun',
                    color: const Color(0xFFF72585), // Pink
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildKidsDestination({
    required IconData icon,
    required String label,
    required Color color,
    required int index,
  }) {
    final isSelected = currentPageIndex == index;

    return NavigationDestination(
      icon: Icon(
          icon,
          color: Colors.grey.withOpacity(0.5),
          size: 26
      ),
      selectedIcon: Transform.scale(
        scale: 1.2, // Make active icon pop out
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      label: label,
    );
  }
}