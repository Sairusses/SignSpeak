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
    final formattedCategory = widget.category.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fb),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
        title: Text(
          formattedCategory,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      )
          : gifs.isEmpty
          ? Center(
        child: Text(
          "No GIFs found for this category.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      )
          : ListView.separated(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: gifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final gif = gifs[index];
          return _buildGifListTile(gif);
        },
      ),
    );
  }

  Widget _buildGifListTile(Map<String, dynamic> gif) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showGifDialog(gif['text'], gif['gif_url']),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigoAccent.shade100,
              Colors.blueAccent.shade200,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          title: Text(
            gif['text'] ?? "Unnamed Sign",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  void _showGifDialog(String? title, String gifUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: gifUrl,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    gifUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title ?? "Unknown Sign",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.close),
                label: Text(
                  "Close",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
