import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gap/gap.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:signspeak/services/landmark_painter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignToTextPage extends StatefulWidget {
  const SignToTextPage({super.key});

  @override
  State<SignToTextPage> createState() => _SignToTextPageState();
}

class _SignToTextPageState extends State<SignToTextPage> with SingleTickerProviderStateMixin {
  // Modes
  int selectedMode = 1; // 0 = Real-time, 1 = Runtime

  // Cameras
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool _isRecording = false;
  int _selectedCameraIndex = 0;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Hand Landmark
  HandLandmarkerPlugin? _plugin;
  List<Hand> _landmarks = [];
  List<Hand> _previousHands = [];
  bool _isInitialized = false;
  bool _isDetecting = false;

  // Results
  List<XFile> pictures = [];
  List<String> predicted_letters = [];
  List<double> confidences = [];
  String _translatedText = '';
  String _processedText = '';
  bool _showProcessed = true;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _rotationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this,);
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),);
    _initializeSystem();
  }
  @override
  void dispose() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _plugin?.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  // Initializations
  Future<void> _initializeSystem() async {
    await initializeCamera(_selectedCameraIndex);
    await initializeHandLandmark();
  }
  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }
  Future<void> initializeCamera(int cameraIndex) async {
    // Dispose the old camera controller before creating a new one
    if (cameraController != null) {
      await cameraController!.dispose();
    }

    // Get available cameras if not already fetched
    cameras ??= await availableCameras();

    if (cameras != null && cameras!.isNotEmpty) {
      cameraController = CameraController(
        cameras![cameraIndex],
        ResolutionPreset.low,
        enableAudio: false,
      );

      try {
        await cameraController!.initialize();
        if (mounted) {
          setState(() {
            isCameraInitialized = true;
            _selectedCameraIndex = cameraIndex;
          });
        }
      } catch (e) {
        debugPrint("Error initializing camera: $e");
      }
    }
  }
  // Camera Functions
  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    final newIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    await initializeCamera(newIndex);
    await initializeHandLandmark();
  }
  Future<void> _startVideoRecording() async {
    if (_isRecording) return;

    setState(() {
      pictures.clear();
      predicted_letters.clear();
      confidences.clear();
      _translatedText = '';
      _processedText = '';
    });

    setState(() {
      _isRecording = true;
    });

  }
  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });
    _processedText = await processText(_translatedText) ?? '';
    debugPrint("Recording stopped — frame processing paused.");
  }
  // Sign Translations
  Future<void> initializeHandLandmark() async {
    _plugin = HandLandmarkerPlugin.create(
      numHands: 1, // The maximum number of hands to detect.
      minHandDetectionConfidence: 0.7, // The minimum confidence score for detection.
      delegate: HandLandmarkerDelegate.GPU, // The processing delegate (GPU or CPU).
    );
    await cameraController!.startImageStream(_processCameraImage);
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }
  Future<void> _processCameraImage(CameraImage image) async {
    // If detection is already in progress, skip this frame.
    if (_isDetecting || !_isInitialized || _plugin == null) return;

    // Set the flag to true to indicate processing has started.
    _isDetecting = true;

    try {
      final hands = _plugin!.detect(
        image,
        cameraController!.description.sensorOrientation,
      );
      if (mounted) {
        setState(() => _landmarks = hands);
      }

      // Detect change compared to previous landmarks
      if (_previousHands.isNotEmpty && hands.isNotEmpty && _previousHands.isNotEmpty) {
        final currentHand = hands.first;
        final previousHand = _previousHands.first;

        bool significantChange = _hasSignificantChange(previousHand, currentHand);
        // get predicted_letter
        if (significantChange && _isRecording) {
          try {
            final XFile imageFile = await cameraController!.takePicture();

            // Send to API
            final result = await _predictSignLanguage(File(imageFile.path));
            debugPrint(result.toString());

            if (result != null) {
              final predictedLetter = result['predicted_letter'];
              final confidence = result['confidence'];
              debugPrint("Detected: $predictedLetter ($confidence)");

              // Append to translated text
              if(confidence > 0.07){
                setState(() {
                  pictures.add(imageFile);
                  predicted_letters.add(predictedLetter);
                  confidences.add(confidence);
                  _translatedText += predictedLetter;
                });
              }
            }
          } catch (e) {
            debugPrint("Error capturing or sending frame: $e");
          }
        }
      }
      if (mounted) {
        setState(() => _previousHands = _landmarks);
      }
    } catch (e) {
      debugPrint('Error detecting landmarks: $e');
    } finally {
      _isDetecting = false;
    }
  }
  Future<String?> processText(String text) async {
    final apiKey = dotenv.env['GROQ'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("GROQ API key not found in .env");
      return null;
    }

    final uri = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    final body = jsonEncode({
      "messages": [
        {
          "role": "system",
          "content":
          "You are an AI text corrector. Return only the normalized and autocorrected version of the provided text without adding explanations or extra punctuation."
        },
        {
          "role": "user",
          "content": text
        }
      ],
      "model": "openai/gpt-oss-120b",
      "temperature": 1,
      "max_completion_tokens": 8192,
      "top_p": 1,
      "stream": false,
      "reasoning_effort": "high",
      "stop": null,
      "tools": []
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final correctedText =
        data["choices"]?[0]?["message"]?["content"]?.trim();
        debugPrint("Corrected text: $correctedText");
        return correctedText;
      } else {
        debugPrint("Text process failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠Error during text process: $e");
    }
    return null;
  }
  bool _hasSignificantChange(Hand prev, Hand curr, {double threshold = 0.15}) {
    // both hands must have same number of landmarks (21)
    if (prev.landmarks.length != curr.landmarks.length) return true;

    for (int i = 0; i < prev.landmarks.length; i++) {
      final dx = (curr.landmarks[i].x - prev.landmarks[i].x).abs();
      final dy = (curr.landmarks[i].y - prev.landmarks[i].y).abs();
      final dz = (curr.landmarks[i].z - prev.landmarks[i].z).abs();

      // if any coordinate changed significantly
      if (dx > threshold || dy > threshold || dz > threshold) {
        return true;
      }
    }

    return false;
  }
  Future<Map<String, dynamic>?> _predictSignLanguage(File imageFile) async {
    try {
      final uri = Uri.parse("https://sairusses-alphabet-sign-api.hf.space/predict");
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(responseBody));
      } else {
        debugPrint("Error: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      debugPrint("Error predicting sign: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||  !isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
      final controller = cameraController!;
      final previewSize = controller.value.previewSize!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(8),
            // Camera
            Stack(
              children: [
                // Camera Preview
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * .8,
                    height: MediaQuery.of(context).size.height * .5,
                    child: AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        child: Stack(
                          children: [
                            CameraPreview(cameraController!),
                            CustomPaint(
                              size: Size.infinite,
                              painter: LandmarkPainter(
                                hands: _landmarks,
                                previewSize: previewSize,
                                lensDirection: controller.description.lensDirection,
                                sensorOrientation: controller.description.sensorOrientation,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // switch camera
                Positioned(
                  bottom: 20,
                  right: 30,
                  child: AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 6.28,
                        child: IconButton(
                          onPressed: () async {
                            await _rotationController.forward(from: 0);
                            _switchCamera();
                          },
                          icon: const Icon(
                              CupertinoIcons.switch_camera_solid,
                              color: Colors.white,
                              size: 35),
                        ),
                      );
                    },
                  ),
                ),
                // Record Button
                Positioned(
                  bottom: 25,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IconButton.outlined(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.fiber_manual_record,
                        color: _isRecording ? Colors.white : Colors.red,
                        size: 55,
                      ),
                      onPressed: () {
                        if (_isRecording) {
                          _stopVideoRecording();
                        } else {
                          _startVideoRecording();
                        }
                      },
                    ),
                  ),
                ),

              ],
            ),
            const Gap(8),
            // Text Output
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Translated Text:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (_processedText.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showProcessed = !_showProcessed;
                            });
                          },
                          child: Text(
                            _showProcessed ? "Show Raw" : "Show Corrected",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _processedText.isEmpty
                        ? (_translatedText.isEmpty
                        ? "No text yet..."
                        : _translatedText)
                        : (_showProcessed ? _processedText : _translatedText),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            // Pictures carousel
            if (pictures.isNotEmpty && !_isRecording) ...[
              const SizedBox(height: 16),
              const Text(
                "Captured Signs",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CarouselSlider.builder(
                itemCount: pictures.length,
                itemBuilder: (context, index, realIdx) {
                  final img = pictures[index];
                  final letter = predicted_letters[index];
                  final conf = confidences[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(img.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Prediction: $letter",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Confidence: ${(conf * 1000).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 300,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  viewportFraction: 0.8,
                  autoPlay: false,
                ),
              ),
            ],
          ],
        ),
      )
    );
  }
}