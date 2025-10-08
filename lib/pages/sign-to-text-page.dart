import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:gap/gap.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:signspeak/services/landmark_painter.dart';


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

  // Storage
  late XFile video;

  // Hand Landmark
  HandLandmarkerPlugin? _plugin;
  List<Hand> _landmarks = [];
  bool _isInitialized = false;
  bool _isDetecting = false;



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

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    final newIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    await initializeCamera(newIndex);
  }

  Future<void> _startVideoRecording() async {
    if (cameraController == null || cameraController!.value.isRecordingVideo) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');

    await cameraController!.startVideoRecording();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopVideoRecording() async {
    if (cameraController == null || !cameraController!.value.isRecordingVideo) return;

    video = await cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });

    // TODO: Send video to backend for runtime translation
  }

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
      // The detect method is now synchronous and returns the results directly.
      final hands = _plugin!.detect(
        image,
        cameraController!.description.sensorOrientation,
      );
      if (mounted) {
        setState(() => _landmarks = hands);
      }
    } catch (e) {
      debugPrint('Error detecting landmarks: $e');
    } finally {
      // Set the flag back to false to allow the next frame to be processed.
      _isDetecting = false;
    }
  }

    @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
      final controller = cameraController!;
      final previewSize = controller.value.previewSize!;
      final previewAspectRatio = previewSize.height / previewSize.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: isCameraInitialized
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Switch
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Translation Mode", textAlign: TextAlign.start, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 125,
                        child: ChoiceChip(
                          label: const Text("Real-time",
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
                      SizedBox(
                        width: 125,
                        child: ChoiceChip(
                          label: const Text("Runtime",
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
            const Gap(8),
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * .8,
                    height: MediaQuery.of(context).size.height * .5,
                    child: ClipRRect( // Clip to a rounded rectangle if needed
                      borderRadius: BorderRadius.circular(15.0),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: AspectRatio(
                              aspectRatio: cameraController!.value.aspectRatio,
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
                              )
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // switch camera
                Positioned(
                  bottom: 10,
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
                // show record button if in RUNTIME mode
                if (selectedMode == 1)
                  Positioned(
                    bottom: 10,
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
                // Show translation prediction if in REAL-TIME mode
                if(selectedMode == 0)
                  Positioned(
                  top: 10,
                  left: 40,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prediction: ',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(
                            'Confidence: %',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                              ? "Current: "
                              : "Record video and send to backend...",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ]),
                ),
              ),
            ),
            const Gap(8),
          ],
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}