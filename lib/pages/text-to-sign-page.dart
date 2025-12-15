import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pose/pose.dart';
import 'package:flutter/foundation.dart';
import 'package:signspeak/services/history_db.dart';
import 'package:signspeak/services/history_item.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';
import 'dart:async';

class TextToSignPage extends StatefulWidget {
  const TextToSignPage({super.key});

  @override
  State<TextToSignPage> createState() => _TextToSignPageState();
}

class _TextToSignPageState extends State<TextToSignPage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  File? gifFile;
  List<HistoryItem> history = [];
  String _lastTranslatedText = "";
  final supabase = Supabase.instance.client;
  final SpeechToText _speech = SpeechToText();
  Timer? _timer;
  bool _isListening = false;
  String _spokenText = "";

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      debugPrint("Speech recognition not available");
    }
  }
  Future<void> _startListening() async {
    _timer?.cancel();
    await _speech.listen(
      localeId: "en_US", //
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
    );
    setState(() => _isListening = true);
    _timer = Timer(const Duration(seconds: 5), () {
      if (_isListening) {
        _stopListening();
      }
    });
  }
  Future<void> _stopListening() async {
    _timer?.cancel();
    await _speech.stop();
    setState(() => _isListening = false);
  }
  void _toggleMic() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _loadHistory() async {
    history = await HistoryDatabase.instance.fetchAll();
    setState(() {});
  }
  Future<void> fetchPoseAndVisualize(String userInput) async {
    try {
      setState(() {
        isLoading = true;
        gifFile = null;
      });

      final translatedText = await _translateToEnglish(userInput);

      final localHistory = await HistoryDatabase.instance.getByText(userInput);
      if (localHistory != null) {
        final file = File(localHistory.gifPath);
        if (await file.exists()) {
          setState(() {
            gifFile = file;
            isLoading = false;
          });
          return;
        }
      }

      final existing = await supabase
          .from('sign_gifs')
          .select()
          .eq('text', translatedText)
          .maybeSingle();

      if (existing != null) {
        final String gifUrl = existing['gif_url'];
        final response = await http.get(Uri.parse(gifUrl));

        final dir = await getTemporaryDirectory();
        final localPath =
            '${dir.path}/cached_${DateTime.now().millisecondsSinceEpoch}.gif';
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        final historyItem = HistoryItem(
          text: userInput,
          gifPath: file.path,
          timestamp: DateTime.now().toIso8601String(),
        );
        await HistoryDatabase.instance.insert(historyItem);
        await _loadHistory();

        setState(() {
          gifFile = file;
          isLoading = false;
        });
        return;
      }

      final url =
          "https://us-central1-sign-mt.cloudfunctions.net/spoken_text_to_signed_pose?text=${Uri.encodeComponent(translatedText)}&spoken=en&signed=ase";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch pose: ${response.statusCode}");
      }
      Uint8List fileContent = response.bodyBytes;
      Pose pose = Pose.read(fileContent);

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/sign_${DateTime.now().millisecondsSinceEpoch}.gif';
      File savedGif = await compute(_generateGif, {"pose": pose, "path": path});

      final gifBytes = await savedGif.readAsBytes();
      final fileName = "sign_${DateTime.now().millisecondsSinceEpoch}.gif";

      await supabase.storage.from('gifs').uploadBinary(
        fileName,
        gifBytes,
        fileOptions: const FileOptions(contentType: "image/gif"),
      );

      final publicUrl = supabase.storage.from('gifs').getPublicUrl(fileName);

      await supabase.from('sign_gifs').insert({
        'text': userInput,
        'gif_url': publicUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      final historyItem = HistoryItem(
        text: userInput,
        gifPath: savedGif.path,
        timestamp: DateTime.now().toIso8601String(),
      );
      await HistoryDatabase.instance.insert(historyItem);
      await _loadHistory();

      setState(() {
        gifFile = savedGif;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading pose: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  static Future<File> _generateGif(Map<String, dynamic> params) async {
    Pose pose = params["pose"];
    String path = params["path"];
    PoseVisualizer p = PoseVisualizer(pose, thickness: 2);
    return await p.saveGif(path, p.draw());
  }
  Future<String> _translateToEnglish(String text) async {
    final uri = Uri.parse(
      "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=en&dt=t&q=${Uri.encodeComponent(text)}",
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return text;

    final data = jsonDecode(response.body);
    final english = data[0][0][0];
    return english;
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    fetchPoseAndVisualize(text);
    _stopListening();
    setState(() {
      _lastTranslatedText = text;
    });
    _controller.clear();
  }
  void _showHistoryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final tileColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.15);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Translation History",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: subTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // History List
              Expanded(
                child: history.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 60, color: subTextColor),
                      const SizedBox(height: 8),
                      Text(
                        "No translation history yet",
                        style: GoogleFonts.poppins(
                          color: subTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          gifFile = File(item.gifPath);
                          _lastTranslatedText = item.text;
                        });
                        Navigator.pop(context);
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(item.gifPath),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            item.text,
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy • hh:mm a')
                                .format(DateTime.parse(item.timestamp)),
                            style: GoogleFonts.poppins(
                              color: subTextColor,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              size: 16, color: subTextColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- KIDS THEME PALETTE ---
    // Defining colors locally for clarity.
    // In a real app, put these in your AppTheme.
    final Color bgBase = const Color(0xFFE0F7FA); // Light Cyan
    final Color primaryPop = const Color(0xFFFF4081); // Bubblegum Pink
    final Color secondaryPop = const Color(0xFF00E5FF); // Bright Cyan
    final Color softWhite = const Color(0xFFFFFFFF);
    final Color textDark = const Color(0xFF2D3142); // Soft Navy (instead of black)
    final Color frameColor = const Color(0xFFFFD54F); // Sunshine Yellow

    return Scaffold(
      backgroundColor: bgBase,
      // Using a Stack to add playful background bubbles
      body: Stack(
        children: [
          // Decorative Background Bubble 1 (Top Left)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: secondaryPop.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Decorative Background Bubble 2 (Bottom Right)
          Positioned(
            bottom: 100,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: primaryPop.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- HEADER ---
                Text(
                  "👋 Text to Sign!",
                  style: GoogleFonts.fredoka( // Changed to a rounded, fun font
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 32, // Bigger title
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                      color: softWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                      ]
                  ),
                  child: Text(
                    "Type a word to see magic hands! ✨",
                    style: GoogleFonts.fredoka(
                      color: textDark.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // --- THE "TV" SCREEN (GIF SECTION) ---
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: softWhite,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: frameColor, width: 8), // Chunky border
                        boxShadow: [
                          BoxShadow(
                            color: frameColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: isLoading
                            ? CircularProgressIndicator(
                          color: primaryPop,
                          strokeWidth: 6, // Thicker loader
                        )
                            : gifFile != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            gifFile!,
                            fit: BoxFit.contain,
                            key: ValueKey(gifFile!.path),
                          ),
                        )
                            : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sentiment_very_satisfied_rounded,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              "Waiting for you!",
                              style: GoogleFonts.fredoka(
                                color: Colors.grey[400],
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // --- LAST TRANSLATED WORD ---
                if (_lastTranslatedText.isNotEmpty && !isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: secondaryPop.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        _lastTranslatedText.toUpperCase(),
                        style: GoogleFonts.fredoka(
                          color: textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                // --- CHUNKY INPUT AREA ---
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: softWhite,
                    borderRadius: BorderRadius.circular(35), // Very round
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF90CAF9).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // History Button
                      _buildKidButton(
                        icon: Icons.history_rounded,
                        color: Colors.orangeAccent,
                        onTap: () => _showHistoryDialog(),
                      ),

                      const SizedBox(width: 8),

                      // Input Field
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.fredoka(
                              color: textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w500
                          ),
                          decoration: InputDecoration(
                            hintText: "Type here...",
                            hintStyle: GoogleFonts.fredoka(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onSubmitted: (text) => _handleSend(),
                        ),
                      ),

                      // Mic Button
                      _buildKidButton(
                        icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isListening ? Colors.redAccent : secondaryPop,
                        onTap: _toggleMic,
                      ),

                      const SizedBox(width: 8),

                      // Send Button
                      _buildKidButton(
                        icon: Icons.send_rounded,
                        color: primaryPop,
                        onTap: _handleSend,
                        isFilled: true, // Make this one solid filled
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper widget to make consistent bouncy buttons
  Widget _buildKidButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFilled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isFilled ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isFilled ? Colors.white : color,
          size: 24,
        ),
      ),
    );
  }
}
