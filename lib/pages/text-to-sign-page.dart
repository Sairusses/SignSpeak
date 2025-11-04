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

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
          .eq('text', userInput)
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
          "https://us-central1-sign-mt.cloudfunctions.net/spoken_text_to_signed_pose?text=${Uri.encodeComponent(userInput)}&spoken=en&signed=ase";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f8fb),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              "Text to Sign",
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Type text and view its sign language translation",
              style: GoogleFonts.poppins(
                color: Colors.grey,
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
                    children: const [
                      Icon(Icons.sign_language,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        "No animation yet",
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_lastTranslatedText.isNotEmpty && !isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _lastTranslatedText,
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
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
                    icon: const Icon(Icons.history, color: Colors.blue),
                    onPressed: () => _showHistoryDialog(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (text) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.blue),
                    onPressed: () {
                      // TODO: integrate speech-to-text
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.blue),
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
    _controller.clear();
  }

  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(item.gifPath),
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(item.text),
              subtitle: Text(
                DateFormat('MMM d, yyyy • hh:mm a')
                    .format(DateTime.parse(item.timestamp)),
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                setState(() {
                  gifFile = File(item.gifPath);
                  _lastTranslatedText = item.text;
                });
                Navigator.pop(context);
                FocusScope.of(context).unfocus();
              },
            ),
          );
        },
      ),
    );
  }
}
