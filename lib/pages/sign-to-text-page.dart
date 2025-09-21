import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'dart:typed_data' as td;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:gap/gap.dart';

class SignToTextPage extends StatefulWidget {
  const SignToTextPage({super.key});

  @override
  State<SignToTextPage> createState() => _SignToTextPageState();
}

class _SignToTextPageState extends State<SignToTextPage>
    with SingleTickerProviderStateMixin {
  // Modes
  int selectedMode = 0; // 0 = Real-time, 1 = Runtime

  // Cameras
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool _isRecording = false;
  int _selectedCameraIndex = 1;

  // Storage
  late XFile video;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // TFLite
  late Interpreter _interpreter;
  bool _isInterpreterReady = false;
  bool _isProcessingFrame = false;
  String _predictedChar = '';
  double _confidence = 0.0;
  final Duration _frameThrottleDuration = Duration(milliseconds: 500);
  DateTime _lastFrameProcessed = DateTime.now();
  final List<String> labels = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U',
    'V', 'W', 'X', 'Y', 'Z',
    'Space', 'Delete', 'Nothing'
  ];

  @override
  void initState() {
    super.initState();
    requestPermissions();
    loadModel();
    initializeCamera(_selectedCameraIndex);
  }

  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _interpreter.close();
    cameraController?.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/1.tflite');
    setState(() {
      _isInterpreterReady = true;
    });
  }

  td.Uint8List yuv420ToRgb(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final img.Image rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final int uvRow = uvRowStride * (y >> 1);
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvRow + (x >> 1) * uvPixelStride;
        final int index = y * width + x;

        final int yp = image.planes[0].bytes[index];
        final int up = image.planes[1].bytes[uvIndex];
        final int vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round();
        int g = (yp -
            up * 46549 / 131072 +
            44 -
            vp * 93604 / 131072 +
            91)
            .round();
        int b = (yp + up * 1814 / 1024 - 227).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return td.Uint8List.fromList(img.encodeJpg(rgbImage));
  }

  img.Image preprocessImage(td.Uint8List imageData, int inputSize) {
    img.Image image = img.decodeImage(imageData)!;
    img.Image resizedImage =
    img.copyResize(image, width: inputSize, height: inputSize);
    return resizedImage;
  }

  List<List<List<double>>> normalizeImage(img.Image image) {
    return List.generate(
      image.height,
          (y) => List.generate(
        image.width,
            (x) {
          final pixel = image.getPixel(x, y);
          final r = (pixel.rNormalized * 2.0) - 1.0;
          final g = (pixel.gNormalized * 2.0) - 1.0;
          final b = (pixel.bNormalized * 2.0) - 1.0;

          return [r, g, b]; // RGB in [-1,1]
        },
      ),
    );
  }

  void runInference(List<List<List<double>>> inputImage) {
    final input = [inputImage];
    final output = List.filled(29, 0).reshape([1, 29]);

    _interpreter.run(input, output);

    final confidences = output[0];
    int maxIndex = 0;
    double maxConfidence = confidences[0];

    for (int i = 1; i < confidences.length; i++) {
      if (confidences[i] > maxConfidence) {
        maxConfidence = confidences[i];
        maxIndex = i;
      }
    }

    setState(() {
      _predictedChar = labels[maxIndex];
      _confidence = maxConfidence;
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final rgbBytes = yuv420ToRgb(image);
      final processedImage = preprocessImage(rgbBytes, 224);
      final normalizedImage = normalizeImage(processedImage);
      runInference(normalizedImage);
    } catch (e) {
      print("Error processing camera image: $e");
    }
  }

  Future<void> initializeCamera(int cameraIndex) async {
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      cameraController = CameraController(
        cameras![_selectedCameraIndex],
        ResolutionPreset.low,
        enableAudio: false,
      );
      await cameraController!.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }

      // Only enable stream in REAL-TIME mode
      cameraController!.startImageStream((CameraImage image) {
        if (selectedMode == 0) {
          final now = DateTime.now();
          if (_isInterpreterReady &&
              !_isProcessingFrame &&
              now.difference(_lastFrameProcessed) > _frameThrottleDuration) {
            _isProcessingFrame = true;
            _lastFrameProcessed = now;

            _processCameraImage(image).then((_) {
              _isProcessingFrame = false;
            });
          }
        }
      });
    }
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    await initializeCamera(_selectedCameraIndex);
  }

  Future<void> _startVideoRecording() async {
    if (cameraController == null ||
        cameraController!.value.isRecordingVideo) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
    path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');

    await cameraController!.startVideoRecording();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopVideoRecording() async {
    if (cameraController == null ||
        !cameraController!.value.isRecordingVideo) return;

    video = await cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });

    // TODO: Send video to backend for runtime translation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isInterpreterReady && isCameraInitialized
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Switch
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Translation Mode", textAlign: TextAlign.start, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Real-time\nLive translate",
                                textAlign: TextAlign.center),
                            selected: selectedMode == 0,
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                                color: selectedMode == 0
                                    ? Colors.white
                                    : Colors.black),
                            onSelected: (_) {
                              setState(() => selectedMode = 0);
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Runtime\nRecord translate",
                                textAlign: TextAlign.center),
                            selected: selectedMode == 1,
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                                color: selectedMode == 1
                                    ? Colors.white
                                    : Colors.black),
                            onSelected: (_) {
                              setState(() => selectedMode = 1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(20),

            // Camera Preview
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                children: [
                  CameraPreview(cameraController!),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 6.28,
                          child: IconButton.filledTonal(
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
                  if(selectedMode == 0)
                    Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prediction: $_predictedChar',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // Translation Section
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Translation",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const Gap(8),
                        Text(
                          selectedMode == 0
                              ? "Current: $_predictedChar ($_confidence)"
                              : "Record video and send to backend...",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ]),
                ),
              ),
            ),
            const Gap(20),

            // Record Button (only for Runtime)
            if (selectedMode == 1)
              Center(
                child: FloatingActionButton.extended(
                  backgroundColor:
                  _isRecording ? Colors.red : Colors.purple,
                  icon: Icon(
                      _isRecording ? Icons.stop : Icons.fiber_manual_record),
                  label: Text(_isRecording ? "Stop" : "Record"),
                  onPressed: () {
                    if (_isRecording) {
                      _stopVideoRecording();
                    } else {
                      _startVideoRecording();
                    }
                  },
                ),
              ),
          ],
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}