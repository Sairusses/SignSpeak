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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xfff9f9fb);
    final keyColor = isDark ? const Color(0xFF1C1F26) : Colors.white;
    final keyTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
        children: [
          const SizedBox(height: 40),

          // TITLE
          Text(
            "ALPHABETS",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          // EXPANDED PREVIEW AREA
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.blueAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: selectedLetter == null
                  ? Center(
                child: Text(
                  "Tap a letter to view",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      selectedAsset!,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // LETTER
                  Text(
                    selectedLetter!,
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // KEYBOARD GRID
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,  // keyboard-like tight grid
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: gifs.length,
                itemBuilder: (context, index) {
                  final item = gifs[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLetter = item["text"];
                        selectedAsset = item["asset_path"];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: keyColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                            isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                        border: Border.all(
                          color: selectedLetter == item["text"]
                              ? Colors.blueAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          item["text"],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: keyTextColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}