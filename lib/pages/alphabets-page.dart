import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlphabetsPage extends StatefulWidget {
  const AlphabetsPage({super.key});

  @override
  State<AlphabetsPage> createState() => _AlphabetsPageState();
}

class _AlphabetsPageState extends State<AlphabetsPage> {
  List<Map<String, dynamic>> gifs = [];
  bool loading = true;

  String? selectedLetter;
  String? selectedAsset;

  // KIDS PALETTE: Vibrant, candy-like colors
  final List<Color> _blockColors = [
    const Color(0xFFFF6B6B), // Red/Pink
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFFFFD93D), // Yellow
    const Color(0xFF6A0572), // Purple
    const Color(0xFFFF9F1C), // Orange
  ];

  @override
  void initState() {
    super.initState();
    loadLocalAlphabetGifs();
  }

  Future<void> loadLocalAlphabetGifs() async {
    try {
      List<String> letters = List.generate(26, (i) => String.fromCharCode(65 + i));

      gifs = letters.map((letter) {
        final lower = letter.toLowerCase();
        return {
          "text": letter,
          "asset_path": "assets/alphabet/$lower.jpeg",
        };
      }).toList();

      setState(() => loading = false);
    } catch (e) {
      debugPrint("Error loading alphabet assets: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine background brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Background color: Soft Mint in Light Mode (Not blue/cream), Deep Navy in Dark Mode
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE3FDF5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ------------------------------------------------
          // 1. PLAYFUL BACKGROUND SHAPES (STACK & CIRCLES)
          // ------------------------------------------------
          if (!isDark) ...[
            Positioned(
              top: -50,
              left: -50,
              child: _buildCircle(200, const Color(0xFFFFD93D).withOpacity(0.3)), // Yellow blob
            ),
            Positioned(
              top: 100,
              right: -30,
              child: _buildCircle(120, const Color(0xFFFF6B6B).withOpacity(0.2)), // Red blob
            ),
            Positioned(
              bottom: -40,
              left: 40,
              child: _buildCircle(180, const Color(0xFF4ECDC4).withOpacity(0.25)), // Teal blob
            ),
            Positioned(
              bottom: 200,
              right: 20,
              child: _buildCircle(60, const Color(0xFF6A0572).withOpacity(0.15)), // Purple dot
            ),
          ],

          // ------------------------------------------------
          // 2. MAIN CONTENT
          // ------------------------------------------------
          loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B6B)))
              : SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // TITLE HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.orange, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      "ALPHABETS",
                      style: GoogleFonts.fredoka( // Friendly rounded font
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF2D3436),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.star_rounded, color: Colors.orange, size: 32),
                  ],
                ),

                const SizedBox(height: 15),

                // DISPLAY AREA (TV / BOARD STYLE)
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16213E) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF4ECDC4),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ECDC4).withOpacity(0.4),
                          blurRadius: 0, // Solid shadow for cartoon look
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: selectedLetter == null
                          ? _buildEmptyState()
                          : _buildSelectedState(isDark),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // KEYBOARD GRID (CANDY BLOCKS)
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20, top: 10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // Wider buttons for kids
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: gifs.length,
                      itemBuilder: (context, index) {
                        final item = gifs[index];
                        final colorIndex = index % _blockColors.length;
                        final btnColor = _blockColors[colorIndex];
                        final isSelected = selectedLetter == item["text"];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedLetter = item["text"];
                              selectedAsset = item["asset_path"];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? btnColor.withOpacity(0.8) : btnColor,
                              borderRadius: BorderRadius.circular(16),
                              // 3D Block Effect
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black.withOpacity(0.2),
                                  width: isSelected ? 0 : 6.0,
                                ),
                              ),
                              boxShadow: isSelected
                                  ? []
                                  : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            transform: isSelected
                                ? Matrix4.translationValues(0, 4, 0) // Push down effect
                                : Matrix4.identity(),
                            child: Center(
                              child: Text(
                                item["text"],
                                style: GoogleFonts.fredoka(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: const Offset(1, 1),
                                        blurRadius: 2,
                                      )
                                    ]
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for background circles
  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      key: const ValueKey("empty"),
      children: [
        const Icon(Icons.touch_app_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 10),
        Text(
          "Pick a Letter!",
          style: GoogleFonts.fredoka(
            fontSize: 20,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      key: ValueKey(selectedLetter),
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                selectedAsset!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, size: 50, color: Colors.redAccent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD93D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            selectedLetter!,
            style: GoogleFonts.fredoka(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3436),
            ),
          ),
        ),
      ],
    );
  }
}