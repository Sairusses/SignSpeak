import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:signspeak/services/landmark_painter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class SignToTextPage extends StatefulWidget {
  final double threshold;
  const SignToTextPage({super.key, required this.threshold});

  @override
  State<SignToTextPage> createState() => _SignToTextPageState();
}

class _SignToTextPageState extends State<SignToTextPage> with SingleTickerProviderStateMixin {
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
  int _stableFrameCount = 0;
  List<Hand> _landmarks = [];
  List<Hand> _previousHands = [];
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isProcessing = false;

  // Results
  List<XFile> pictures = [];
  List<String> predicted_letters = [];
  List<double> confidences = [];
  String _translatedText = '';
  String _processedText = '';
  bool _showProcessed = true;
  bool _showPanel = false;

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
      _isProcessing = false;
      _showPanel = true;
    });
    _processedText = await processText(_translatedText) ?? '';
    debugPrint("Recording stopped — frame processing paused.");
  }
  // Sign Translations
  Future<void> initializeHandLandmark() async {
    _plugin = HandLandmarkerPlugin.create(
      numHands: 2, // The maximum number of hands to detect.
      minHandDetectionConfidence: 0.7, // The minimum confidence score for detection.
      delegate: HandLandmarkerDelegate.GPU, // The processing delegate (GPU or CPU).
    );
    await cameraController!.startImageStream(_processCameraImage);
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_isInitialized || _plugin == null) return;
    _isDetecting = true;

    try {
      final hands = _plugin!.detect(
        image,
        cameraController!.description.sensorOrientation,
      );

      if (mounted) {
        setState(() => _landmarks = hands);
      }

      if (_previousHands.isNotEmpty && hands.isNotEmpty) {
        final currentHand = hands.first;
        final previousHand = _previousHands.first;

        bool same = _areHandsSame(previousHand, currentHand);

        if (same) {
          _stableFrameCount++;
        } else {
          _stableFrameCount = 0;
        }

        if (_stableFrameCount >= 20 && _isRecording && !_isProcessing) {
          _stableFrameCount = 0;
          try {
            final XFile imageFile = await cameraController!.takePicture();
            setState(() => _isProcessing = true);

            // Crop image around detected hand
            final croppedFile = await _cropHandRegion(
              File(imageFile.path),
              cropSize: 750
            );

            final result = await _predictSignLanguage(croppedFile);
            if (result != null) {
              final predictedLetter = result['predicted_letter'];
              final confidence = result['confidence'];

              if (confidence > 0.4) {
                setState(() {
                  _isProcessing = false;
                  pictures.add(XFile(croppedFile.path));
                  predicted_letters.add(predictedLetter);
                  confidences.add(confidence);
                  _translatedText += predictedLetter;
                });
                debugPrint("Detected: $predictedLetter ($confidence)");
              }
            }
          } catch (e) {
            debugPrint("Error capturing or sending frame: $e");
          } finally {
            setState(() => _isProcessing = false);
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
  Future<File> _cropHandRegion(File imageFile, {required int cropSize,}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) return imageFile;

      final int imgW = original.width;
      final int imgH = original.height;

      // ---- CENTER-BASED CROP ----
      int centerX = imgW ~/ 2;
      int centerY = imgH ~/ 2;

      int half = cropSize ~/ 2;

      int x = (centerX - half).clamp(0, imgW - 1);
      int y = (centerY - half).clamp(0, imgH - 1) - 150;

      int w = (x + cropSize > imgW) ? imgW - x : cropSize;
      int h = (y + cropSize > imgH) ? imgH - y : cropSize;

      final cropped = img.copyCrop(
        original,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      final tempDir = Directory.systemTemp;
      final output = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await output.writeAsBytes(img.encodeJpg(cropped));

      return output;

    } catch (e) {
      debugPrint("Error cropping at center: $e");
      return imageFile;
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
  bool _areHandsSame(Hand prev, Hand curr) {
    final threshold = widget.threshold;
    if (prev.landmarks.length != curr.landmarks.length) return false;

    for (int i = 0; i < prev.landmarks.length; i++) {
      final dx = (curr.landmarks[i].x - prev.landmarks[i].x).abs();
      final dy = (curr.landmarks[i].y - prev.landmarks[i].y).abs();
      final dz = (curr.landmarks[i].z - prev.landmarks[i].z).abs();

      // If any landmark moved more than the threshold, consider it changed
      if (dx > threshold || dy > threshold || dz > threshold) {
        return false;
      }
    }
    return true;
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
    // === 🎨 KID-FRIENDLY COLOR PALETTE ===
    // We ignore system dark mode to keep the app bright and happy always!
    const Color kSkyBlue = Color(0xFF4CB5F9);
    const Color kBananaYellow = Color(0xFFFFD93D);
    const Color kBubblegumPink = Color(0xFFFF6B6B);
    const Color kLimeGreen = Color(0xFF6BCB77);
    const Color kDeepNavy = Color(0xFF2C3E50); // Easier to read than black
    const Color kCreamWhite = Color(0xFFFFF9E5);
    const Color kCardBg = Colors.white;

    if (!_isInitialized || !isCameraInitialized) {
      return Scaffold(
        backgroundColor: kSkyBlue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouncy loading indicator
              CircularProgressIndicator(
                color: kBananaYellow,
                strokeWidth: 6,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(height: 20),
              Text(
                "Loading Camera...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            ],
          ),
        ),
      );
    }

    final previewSize = cameraController!.value.previewSize!;

    return Scaffold(
      backgroundColor: kDeepNavy, // Background behind camera
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== CAMERA PREVIEW =====
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width *
                  cameraController!.value.aspectRatio,
              child: CameraPreview(cameraController!),
            ),
          ),

          // ===== HAND LANDMARK OVERLAY =====
          // We keep the painter logic, but make the loading spinner colorful
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width *
                  cameraController!.value.aspectRatio,
              child: !_isProcessing
                  ? CustomPaint(
                painter: LandmarkPainter(
                  hands: _landmarks,
                  previewSize: previewSize,
                  lensDirection:
                  cameraController!.description.lensDirection,
                  sensorOrientation:
                  cameraController!.description.sensorOrientation,
                ),
              )
                  : Center(
                child: CircularProgressIndicator(
                  color: kBananaYellow,
                  strokeWidth: 5,
                ),
              ),
            ),
          ),

          // ===== CENTER HAND GUIDE (The "Viewfinder") =====
          Align(
            alignment: const Alignment(0, -0.25),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                // Thick playful border
                border: Border.all(
                  color: kBananaYellow.withOpacity(0.8),
                  width: 6, // Chunky border
                ),
                borderRadius: BorderRadius.circular(30), // Super rounded
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: kDeepNavy.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Put Hand Here!",
                    style: TextStyle(
                        color: kBananaYellow,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(2,2))
                        ]
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===== TRANSLATED TEXT OVERLAY (The "Speech Bubble") =====
          if (_translatedText.isNotEmpty)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kSkyBlue, width: 4),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 0,
                      offset: Offset(0, 6), // "3D" effect
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "I see...",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _processedText.isEmpty
                          ? _translatedText
                          : (_showProcessed ? _processedText : _translatedText),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kDeepNavy,
                        fontSize: 28, // Big text
                        fontWeight: FontWeight.w900, // Extra bold
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ===== SWITCH CAMERA BUTTON (The "Green Button") =====
          Positioned(
            bottom: 140,
            right: 30,
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 6.28,
                  child: GestureDetector(
                    onTap: () async {
                      await _rotationController.forward(from: 0);
                      _switchCamera();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kLimeGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 0,
                            offset: Offset(0, 4), // Pushy button effect
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.switch_camera_solid,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ===== RECORD BUTTON (The "Big Red Button") =====
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_isRecording) {
                    _stopVideoRecording();
                  } else {
                    _startVideoRecording();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 80 : 75,
                  height: _isRecording ? 80 : 75,
                  decoration: BoxDecoration(
                    color: _isRecording ? kBubblegumPink : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? Colors.white : kBubblegumPink,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
                    color: _isRecording ? Colors.white : kBubblegumPink,
                    size: 45,
                  ),
                ),
              ),
            ),
          ),

          // ===== MENU BUTTON (The "Blue Button") =====
          Positioned(
            left: 30,
            bottom: 140,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showPanel = !_showPanel;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSkyBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ===== "STICKER BOOK" SIDE PANEL =====
          if (_showPanel && !_isRecording)
            Positioned(
              left: 0,
              top: 20, // Floating slightly
              bottom: 20,
              width: 300,
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: kCreamWhite,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: kSkyBlue, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // --- Header ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSkyBlue,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "MY WORDS",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showPanel = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: Icon(Icons.close_rounded,
                                  color: kBubblegumPink, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Content ---
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Current Text Bubble
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 2),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              "COLLECTION",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: kSkyBlue,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // List of Stickers (Images)
                            Expanded(
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: pictures.length,
                                itemBuilder: (context, index) {
                                  final img = pictures[index];
                                  final letter = predicted_letters[index];
                                  final conf = confidences[index];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          offset: const Offset(0, 4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: kBananaYellow, width: 3),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.file(
                                              File(img.path),
                                              width: 55,
                                              height: 55,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "It looks like:",
                                                style: TextStyle(fontSize: 10, color: Colors.grey),
                                              ),
                                              Text(
                                                "Letter $letter",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 18,
                                                  color: kDeepNavy,
                                                ),
                                              ),
                                              // Fun progress bar instead of just text
                                              Padding(
                                                padding: const EdgeInsets.only(top:4.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: conf,
                                                    backgroundColor: Colors.grey[200],
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                        conf > 0.8 ? kLimeGreen : kBananaYellow
                                                    ),
                                                    minHeight: 8,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}