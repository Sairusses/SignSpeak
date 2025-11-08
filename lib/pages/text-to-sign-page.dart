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
    await _speech.listen(
      localeId: "en_US", // or "fil_PH" for Tagalog
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
    );

    setState(() => _isListening = true);
  }
  Future<void> _stopListening() async {
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Header
            Text(
              "Text to Sign",
              style: GoogleFonts.poppins(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Type text and view its sign language translation",
              style: GoogleFonts.poppins(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontSize: 14,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // GIF Section
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : gifFile != null
                      ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        gifFile!,
                        fit: BoxFit.contain,
                        key: ValueKey(gifFile!.path),
                      ),
                    ),
                  )
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sign_language,
                          size: 80,
                          color:
                          isDark ? Colors.grey[600] : Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        "No animation yet",
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[500]
                              : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Last Translated Text
            if (_lastTranslatedText.isNotEmpty && !isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _lastTranslatedText,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onBackground.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

            // Input Section
            Container(
              height: 70,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[900]?.withOpacity(0.7)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.history,
                        color: colorScheme.primary),
                    onPressed: () => _showHistoryDialog(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 3,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (text) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.stop_circle : Icons.mic,
                      color: colorScheme.primary,
                    ),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: Icon(Icons.send_rounded,
                        color: colorScheme.primary),
                    onPressed: _handleSend,
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
