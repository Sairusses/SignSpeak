import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryPage extends StatefulWidget {
  final String category;
  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final SupabaseClient supabase;
  List<Map<String, dynamic>> gifs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    fetchCategoryGifs();
  }

  Future<void> fetchCategoryGifs() async {
    try {
      final response = await supabase
          .from('sign_gifs')
          .select()
          .eq('category', widget.category)
          .order('created_at', ascending: false);

      setState(() {
        gifs = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching ${widget.category}: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kids Theme: Soft Mint/Cloud background
    final Color bgBase = const Color(0xFFE0F2F1);
    final Color textDark = const Color(0xFF263238);

    // Helper to make "CATEGORY_NAME" -> "Category Name"
    final friendlyTitle = widget.category
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Custom "Back" button that looks like a candy/pill
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))
                ]
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.orange),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          friendlyTitle,
          style: GoogleFonts.fredoka(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 26, // Big title
          ),
        ),
      ),
      body: loading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.orange, strokeWidth: 6),
            const SizedBox(height: 16),
            Text("Loading Magic... ✨", style: GoogleFonts.fredoka(fontSize: 18, color: Colors.grey)),
          ],
        ),
      )
          : gifs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Uh oh! No signs here yet! 🙈",
              style: GoogleFonts.fredoka(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: gifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final gif = gifs[index];
          // Pass index to create color patterns
          return _buildKidListCard(gif, index);
        },
      ),
    );
  }

  Widget _buildKidListCard(Map<String, dynamic> gif, int index) {
    // A fun palette of colors to cycle through
    final List<Color> colors = [
      const Color(0xFF42A5F5), // Blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFFEF5350), // Red
    ];

    final Color cardColor = colors[index % colors.length];

    return GestureDetector(
      onTap: () => _showKidDialog(gif['text'], gif['gif_url']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side: The Color Strip / Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 36),
            ),

            // Right side: The Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        gif['text'] ?? "Mystery Sign",
                        style: GoogleFonts.fredoka(
                          color: const Color(0xFF37474F),
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    // Play Button Icon
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: cardColor,
                      size: 40,
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

  void _showKidDialog(String? title, String gifUrl) {
    showDialog(
      context: context,
      // Dark blur background to focus attention
      barrierColor: const Color(0xFF263238).withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. The "TV Screen" Frame
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 8), // Yellow TV Frame
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        gifUrl,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.orangeAccent,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
                              Text("Oops! Image broken", style: GoogleFonts.fredoka(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // The Title Bar under the image
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD54F), // Match border
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Text(
                        title ?? "Mystery Sign",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: const Color(0xFF5D4037),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Big "Done" Button
              SizedBox(
                width: 160,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4081), // Hot Pink
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Colors.white, width: 3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "Done!",
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}