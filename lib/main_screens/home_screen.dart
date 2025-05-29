import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data' as td;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin{

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

  // TFlite
  late Interpreter _interpreter;
  bool _isInterpreterReady = false;
  bool _isProcessingFrame = false;
  String _predictedChar = '';
  double _confidence = 0.0;
  final Duration _frameThrottleDuration = Duration(milliseconds: 500);
  DateTime _lastFrameProcessed = DateTime.now();


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
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round();
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
    img.Image resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    return resizedImage;
  }

  List<List<List<double>>> normalizeImage(img.Image image) {
    return List.generate(
      image.height,
          (y) => List.generate(
        image.width,
            (x) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          return [r, g, b];
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

    final predictedChar = String.fromCharCode(97 + maxIndex); // 'a' has ASCII code 97
    setState(() {
      _predictedChar = predictedChar;
      _confidence = maxConfidence;
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final rgbBytes = yuv420ToRgb(image);
      final processedImage = preprocessImage(rgbBytes, 224); // Assuming input size is 224x224
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
      cameraController!.startImageStream((CameraImage image) {
        final now = DateTime.now();
        if (_isInterpreterReady && !_isProcessingFrame && now.difference(_lastFrameProcessed) > _frameThrottleDuration) {
          _isProcessingFrame = true;
          _lastFrameProcessed = now;

          _processCameraImage(image).then((_) {
            _isProcessingFrame = false;
          });
        }
      });
    }
  }

  Future<void> _startVideoRecording() async {
    if (cameraController == null || cameraController!.value.isRecordingVideo) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');

    await cameraController!.startVideoRecording();
  }

  Future<void> _stopVideoRecording() async {
    if (cameraController == null || !cameraController!.value.isRecordingVideo) return;

    video = await cameraController!.stopVideoRecording();
  }

  Future<void> _switchCamera() async {
    if (cameras!.length < 2 || cameras == null) return;

    _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    await initializeCamera(_selectedCameraIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SignSpeak",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        scrolledUnderElevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.settings),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.3),
        ),
      ),
      body: _isInterpreterReady && isCameraInitialized
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            cameraWidget(cameraController),
            const SizedBox(height: 20),
          ],
        ),
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),

    );
  }
  Widget cameraWidget(CameraController? cameraController) {
    return SizedBox(
      height: MediaQuery.of(context).size.height *.75,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          cameraController != null ? CameraPreview(cameraController) : Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 10,
            right: 10,
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 6.28, // 180 degrees
                  child: IconButton.filledTonal(
                    onPressed: () async {
                      await _rotationController.forward(from: 0);
                      _switchCamera();
                    },
                    icon: Icon(CupertinoIcons.switch_camera_solid, color: Colors.white, size: 35),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 10,
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
                  Text(
                    'Prediction: $_predictedChar',
                    style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ]
      )
    );
  }
}