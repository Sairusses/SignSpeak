import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pose/pose.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // for compute

class TextToSignPage extends StatefulWidget {
  const TextToSignPage({super.key});

  @override
  State<TextToSignPage> createState() => _TextToSignPageState();
}

class _TextToSignPageState extends State<TextToSignPage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  File? gifFile;
  final supabase = Supabase.instance.client;

  Future<void> fetchPoseAndVisualize(String userInput) async {
    try {
      setState(() {
        isLoading = true;
        gifFile = null;
      });

      // 1. Check if this input already exists in Supabase DB
      final existing = await supabase
          .from('sign_gifs')
          .select()
          .eq('text', userInput)
          .maybeSingle();

      if (existing != null) {
        // ✅ Load GIF from Supabase if already cached
        final String gifUrl = existing['gif_url'];
        final response = await http.get(Uri.parse(gifUrl));

        final dir = await getTemporaryDirectory();
        final localPath =
            '${dir.path}/cached_${DateTime.now().millisecondsSinceEpoch}.gif';
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          gifFile = file;
          isLoading = false;
        });
        return;
      }

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
      File savedGif = await compute(_generateGif, {"pose": pose, "path": path});

      // 4. Upload GIF to Supabase Storage
      final gifBytes = await savedGif.readAsBytes();
      final fileName = "sign_${DateTime.now().millisecondsSinceEpoch}.gif";

      await supabase.storage.from('gifs').uploadBinary(
        fileName,
        gifBytes,
        fileOptions: const FileOptions(contentType: "image/gif"),
      );

      final publicUrl = supabase.storage.from('gifs').getPublicUrl(fileName);

      // 5. Insert record into DB
      await supabase.from('sign_gifs').insert({
        'text': userInput,
        'gif_url': publicUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        gifFile = savedGif;
        isLoading = false;
      });
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
            // GIF / Loader section
            Expanded(
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : (gifFile != null
                    ? Image.file(
                  gifFile!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  key: ValueKey(gifFile!
                      .path), // force rebuild when file path changes
                )
                    : const Text("No animation yet")),
              ),
            ),

            // Input area at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          const BorderSide(color: Colors.grey), // gray
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          const BorderSide(color: Colors.grey), // gray
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          const BorderSide(color: Colors.blue), // blue focus
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