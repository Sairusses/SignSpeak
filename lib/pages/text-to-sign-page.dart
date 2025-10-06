import 'dart:io';
import 'package:flutter/material.dart';
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

      // 1️⃣ Check local history first
      final localHistory = await HistoryDatabase.instance.getByText(userInput);
      if (localHistory != null) {
        final file = File(localHistory.gifPath);
        if (await file.exists()) {
          setState(() {
            gifFile = file;
            isLoading = false;
          });
          return; // ✅ Found locally
        }
      }

      // 2️⃣ Check Supabase DB
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

        // Save to local history
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
        return; // ✅ Found in Supabase
      }

      // 3️⃣ Fetch from API if not found anywhere
      final url =
          "https://us-central1-sign-mt.cloudfunctions.net/spoken_text_to_signed_pose?text=${Uri.encodeComponent(userInput)}&spoken=en&signed=ase";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch pose: ${response.statusCode}");
      }
      Uint8List fileContent = response.bodyBytes;

      // Parse pose
      Pose pose = Pose.read(fileContent);

      // Generate GIF locally
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/sign_${DateTime.now().millisecondsSinceEpoch}.gif';
      File savedGif = await compute(_generateGif, {"pose": pose, "path": path});

      // Upload GIF to Supabase Storage
      final gifBytes = await savedGif.readAsBytes();
      final fileName = "sign_${DateTime.now().millisecondsSinceEpoch}.gif";

      await supabase.storage.from('gifs').uploadBinary(
        fileName,
        gifBytes,
        fileOptions: const FileOptions(contentType: "image/gif"),
      );

      final publicUrl = supabase.storage.from('gifs').getPublicUrl(fileName);

      // Insert record into Supabase DB
      await supabase.from('sign_gifs').insert({
        'text': userInput,
        'gif_url': publicUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Save to local history
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

  // generate gif that runs in isolate
  static Future<File> _generateGif(Map<String, dynamic> params) async {
    Pose pose = params["pose"];
    String path = params["path"];

    PoseVisualizer p = PoseVisualizer(pose, thickness: 2);
    return await p.saveGif(path, p.draw());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Header
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    "Text to Sign",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Type text below and see the sign language animation",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // History button
            Positioned(
              right: 15,
              top: 10,
              child: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => Dialog(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            return ListTile(
                              leading: Image.file(
                                File(item.gifPath),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
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
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                iconSize: 30,
                color: Colors.grey,
              ),
            ),

            // GIF / Loader section with text below
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : (gifFile != null
                          ? Image.file(
                        gifFile!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        key: ValueKey(gifFile!.path), // force rebuild
                      )
                          : const Text("No animation yet")),
                    ),
                  ),
                  if (_lastTranslatedText.isNotEmpty && isLoading == false)
                    Text(
                      _lastTranslatedText,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),

            // Input area at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.white,
                child: TextField(
                  focusNode: FocusNode(canRequestFocus: false),
                  autofocus: false,
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            // TODO: Add speech-to-text here
                          },
                          icon: const Icon(Icons.mic, color: Colors.blue),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (_controller.text.trim().isNotEmpty) {
                              fetchPoseAndVisualize(_controller.text.trim());
                              setState(() {
                                _lastTranslatedText = _controller.text.trim();
                              });
                              _controller.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}