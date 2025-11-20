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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1115) : const Color(0xfff6f8fb);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: _buildAlphabetCard(isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category, isDark);
                },
                childCount: categories.length,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).size.height * 0.12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlphabetCard(bool isDark){
    final gradientColors = isDark
        ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
        : [Colors.indigoAccent.shade100, Colors.blueAccent.shade200];

    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.blueAccent.withOpacity(0.25);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlphabetsPage()),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sort_by_alpha,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                "Alphabets",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isDark) {
    final gradientColors = isDark
        ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)] // darker blue tones
        : [Colors.indigoAccent.shade100, Colors.blueAccent.shade200];

    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.blueAccent.withOpacity(0.25);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryPage(category: category["name"]),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category["icon"],
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                category["name"].replaceAll('_', ' ').toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
