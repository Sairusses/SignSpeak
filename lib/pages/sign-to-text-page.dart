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
    });
    // _processedText = await processText(_translatedText) ?? '';
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

      // If both current and previous hands are detected
      if (_previousHands.isNotEmpty && hands.isNotEmpty) {
        final currentHand = hands.first;
        final previousHand = _previousHands.first;

        // Check if current and previous hand landmarks are almost identical
        bool same = _areHandsSame(previousHand, currentHand);

        if (same) {
          _stableFrameCount++;
        } else {
          _stableFrameCount = 0; // reset if movement detected
        }

        // When hands are stable for 15 consecutive frames
        if (_stableFrameCount >= 15 && _isRecording && !_isProcessing) {
          _stableFrameCount = 0; // reset after capturing

          try {
            final XFile imageFile = await cameraController!.takePicture();
            setState(() => _isProcessing = true);

            final result = await _predictSignLanguage(File(imageFile.path));
            if (result != null) {
              final predictedLetter = result['predicted_letter'];
              final confidence = result['confidence'];

              if (confidence > 0.7) {
                setState(() {
                  _isProcessing = false;
                  pictures.add(imageFile);
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

      // Update previous hand landmarks
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
  bool _hasSignificantChange(Hand prev, Hand curr) {
    final threshold = widget.threshold;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? Colors.black : const Color(0xfff6f8fb);
    final textColor = isDark ? Colors.white : Colors.black87;
    final sheetColor = isDark
        ? Colors.grey[900]!.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);
    final glassColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.white.withOpacity(0.7);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.4);

    if (!_isInitialized || !isCameraInitialized) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.white : Colors.blueAccent,
          ),
        ),
      );
    }

    final controller = cameraController!;
    final previewSize = controller.value.previewSize!;

    return Scaffold(
      backgroundColor: backgroundColor,
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
                lensDirection: controller.description.lensDirection,
                sensorOrientation: controller.description.sensorOrientation,
              ),
            )
                : Center(child: CircularProgressIndicator(color: Color(0xFFB9D9EB)),),
          ),
        ),

        // ===== TRANSLATED TEXT OVERLAY =====
          if (_translatedText.isNotEmpty)
            Positioned(
              bottom: 220,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: glassColor,
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _processedText.isEmpty
                      ? _translatedText
                      : (_showProcessed ? _processedText : _translatedText),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ===== SWITCH CAMERA BUTTON =====
          Positioned(
            bottom: 140,
            right: 25,
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
                    icon: Icon(
                      CupertinoIcons.switch_camera_solid,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),

          // ===== RECORD BUTTON =====
          Positioned(
            bottom: 140,
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
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.redAccent
                        : (isDark ? Colors.white10 : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white54 : Colors.black12,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black45
                            : Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.white : Colors.red,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),

          // ===== DRAGGABLE SLIDER =====
          if (!_isRecording && pictures.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.2,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sheetColor,
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Processed Text",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          if (_processedText.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showProcessed = !_showProcessed;
                                });
                              },
                              child: Text(
                                _showProcessed
                                    ? "Show Raw"
                                    : "Show Corrected",
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
                            : (_showProcessed
                            ? _processedText
                            : _translatedText),
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Captured Signs",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CarouselSlider.builder(
                        itemCount: pictures.length,
                        itemBuilder: (context, index, realIdx) {
                          final img = pictures[index];
                          final letter = predicted_letters[index];
                          final conf = confidences[index];

                          return Container(
                            margin:
                            const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[850]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black54
                                      : Colors.black12,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(16),
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  "Confidence: ${(conf * 100).toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey,
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
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}