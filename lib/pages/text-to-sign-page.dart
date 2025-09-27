import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pose/pose.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TextToSignPage extends StatefulWidget {
  const TextToSignPage({super.key});

  @override
  State<TextToSignPage> createState() => _TextToSignPageState();
}

class _TextToSignPageState extends State<TextToSignPage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  File? gifFile;
  String? translatedText;
  final supabase = Supabase.instance.client;

  // ✅ History: text + gif file
  final List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// ✅ Load history from Supabase DB
  Future<void> _loadHistory() async {
    try {
      final response = await supabase
          .from('sign_gifs')
          .select()
          .order('created_at', ascending: false);

      final dir = await getTemporaryDirectory();

      for (var item in response) {
        final gifUrl = item['gif_url'] as String;
        final gifResponse = await http.get(Uri.parse(gifUrl));

        if (gifResponse.statusCode == 200) {
          final localPath =
              '${dir.path}/hist_${DateTime.now().millisecondsSinceEpoch}.gif';
          final file = File(localPath);
          await file.writeAsBytes(gifResponse.bodyBytes);

          history.add({
            "text": item['text'],
            "gif": file,
          });
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> fetchPoseAndVisualize(String userInput) async {
    try {
      setState(() {
        isLoading = true;
        gifFile = null;
        translatedText = userInput;
      });

      File? loadedFile;

      // 1. Check if this input already exists in Supabase DB
      final existing = await supabase
          .from('sign_gifs')
          .select()
          .eq('text', userInput)
          .maybeSingle();

      if (existing != null) {
        // ✅ Load cached GIF
        final String gifUrl = existing['gif_url'];
        final response = await http.get(Uri.parse(gifUrl));

        final dir = await getTemporaryDirectory();
        final localPath =
            '${dir.path}/cached_${DateTime.now().millisecondsSinceEpoch}.gif';
        loadedFile = File(localPath);
        await loadedFile.writeAsBytes(response.bodyBytes);

        setState(() {
          gifFile = loadedFile;
          isLoading = false;
        });
      } else {
        // 2. Otherwise, fetch .pose from API
        final url =
            "https://us-central1-sign-mt.cloudfunctions.net/spoken_text_to_signed_pose?text=${Uri.encodeComponent(userInput)}&spoken=en&signed=ase";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception("Failed to fetch pose: ${response.statusCode}");
        }

        Uint8List fileContent = response.bodyBytes;
        Pose pose = Pose.read(fileContent);

        // 3. Save GIF locally
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/sign_${DateTime.now().millisecondsSinceEpoch}.gif';
        loadedFile = await compute(_generateGif, {"pose": pose, "path": path});

        // 4. Upload GIF to Supabase Storage
        final gifBytes = await loadedFile!.readAsBytes();
        final fileName = "sign_${DateTime.now().millisecondsSinceEpoch}.gif";

        await supabase.storage.from('gifs').uploadBinary(
          fileName,
          gifBytes,
          fileOptions: const FileOptions(contentType: "image/gif"),
        );

        final publicUrl =
        supabase.storage.from('gifs').getPublicUrl(fileName);

        // 5. Insert record into DB
        await supabase.from('sign_gifs').insert({
          'text': userInput,
          'gif_url': publicUrl,
          'created_at': DateTime.now().toIso8601String(),
        });

        setState(() {
          gifFile = loadedFile;
          isLoading = false;
        });
      }

      // ✅ Add to local history (always insert at top)
      if (loadedFile != null) {
        setState(() {
          history.insert(0, {
            "text": userInput,
            "gif": loadedFile,
          });
        });
      }
    } catch (e) {
      debugPrint("Loading Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function that runs in isolate
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
        child: Column(
          children: [
            // Current translated text + GIF
            Expanded(
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : (gifFile != null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (translatedText != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          translatedText!,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    Image.file(
                      gifFile!,
                      fit: BoxFit.contain,
                      width: 250,
                      key: ValueKey(gifFile!.path),
                    ),
                  ],
                )
                    : const Text("No animation yet")),
              ),
            ),

            // ✅ Translation history
            if (history.isNotEmpty)
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return GestureDetector(
                      onTap: () {
                        // ✅ Load clicked history item
                        setState(() {
                          translatedText = item["text"];
                          gifFile = item["gif"];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(item["text"],
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Image.file(
                              item["gif"],
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Input area
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        fetchPoseAndVisualize(_controller.text.trim());
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}