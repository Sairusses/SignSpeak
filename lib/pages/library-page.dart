import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'alphabets-page.dart';
import 'category-page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final List<Map<String, dynamic>> categories = [
    {"name": "greetings", "icon": Icons.waving_hand_outlined},
    {"name": "questions", "icon": Icons.question_answer_outlined},
    {"name": "common_phrases", "icon": Icons.chat_bubble_outline},
    {"name": "actions", "icon": Icons.run_circle_outlined},
    {"name": "objects", "icon": Icons.category_outlined},
    {"name": "feelings", "icon": Icons.favorite_border},
    {"name": "time", "icon": Icons.access_time},
    {"name": "people", "icon": Icons.people_outline},
    {"name": "places", "icon": Icons.place_outlined},
    {"name": "numbers", "icon": Icons.pin_outlined},
    {"name": "colors", "icon": Icons.palette_outlined},
    {"name": "directions", "icon": Icons.directions_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Define a playful background color
    final Color bgBase = const Color(0xFFFFF3E0); // Soft Cream/Vanilla background

    return Scaffold(
      backgroundColor: bgBase,
      // Using a Stack to add background playfulness
      body: Stack(
        children: [
          // Background Decoration: A big sun/circle in the corner
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC80).withOpacity(0.3), // Soft Orange
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: CustomScrollView(
              slivers: [
                // Header Space
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Big Alphabet Banner
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: double.infinity,
                    height: 140, // Made slightly taller for better touch targets
                    child: _buildAlphabetCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // "Pick a Category" Label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 8),
                    child: Text(
                      "Pick a Topic! 🚀",
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D4037), // Brownish text (warmer than black)
                      ),
                    ),
                  ),
                ),

                // The Grid
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0, // Square cards look more like blocks/toys
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final category = categories[index];
                      // Pass the index to generate a rainbow pattern
                      return _buildCategoryCard(category, index);
                    },
                    childCount: categories.length,
                  ),
                ),

                // Bottom padding for scrolling
                SliverToBoxAdapter(
                    child: SizedBox(height: MediaQuery.of(context).size.height * 0.12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ---------------------------------------------------------
// COMPONENT: The Alphabet Hero Card
// ---------------------------------------------------------
  Widget _buildAlphabetCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlphabetsPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          // Bright Orange to Yellow Gradient
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFFD54F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24), // Squircle
          border: Border.all(color: Colors.white, width: 4), // Cartoon Stroke
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background pattern inside the card
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.abc, size: 120, color: Colors.white.withOpacity(0.2)),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_stories, // Changed icon to book/stories
                      size: 32,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Learn ABCs",
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        "Let's start!",
                        style: GoogleFonts.fredoka(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// ---------------------------------------------------------
// COMPONENT: The Category Blocks
// ---------------------------------------------------------
  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    // Pre-defined palette of fun colors
    final List<Color> cardColors = [
      const Color(0xFF4DD0E1), // Cyan
      const Color(0xFFF06292), // Pink
      const Color(0xFFAED581), // Light Green
      const Color(0xFF7986CB), // Periwinkle
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFBA68C8), // Purple
    ];

    // Cycle through colors based on index (Modulo operator)
    final Color baseColor = cardColors[index % cardColors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryPage(category: category["name"]),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4), // Chunky white border
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25), // Semi-transparent bubble
                shape: BoxShape.circle,
              ),
              child: Icon(
                category["icon"],
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                // Capitalize first letter, lower case the rest for friendliness
                _formatFriendlyText(category["name"]),
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper to turn "MY_CATEGORY" into "My Category"
  String _formatFriendlyText(String text) {
    return text
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1)}'
        : '')
        .join(' ');
  }
}
