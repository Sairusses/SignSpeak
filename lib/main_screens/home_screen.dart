import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin{
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool _isRecording = false;
  int _selectedCameraIndex = 1;
  late XFile video;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
    initializeCamera(_selectedCameraIndex);
    requestPermissions();
  }
  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    controller?.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> initializeCamera(int cameraIndex) async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(
        cameras![_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    }
  }

  Future<void> _startVideoRecording() async {
    if (controller == null || controller!.value.isRecordingVideo) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');

    await controller!.startVideoRecording();
  }

  Future<void> _stopVideoRecording() async {
    if (controller == null || !controller!.value.isRecordingVideo) return;

    video = await controller!.stopVideoRecording();
  }

  Future<void> _switchCamera() async {
    if (cameras!.length < 2 || cameras == null) return;

    _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    await initializeCamera(_selectedCameraIndex);
  }

  Widget cameraWidget(CameraController? cameraController) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      width: MediaQuery.of(context).size.width * 0.7,
      child: Stack(
        children: [
          cameraController != null ? CameraPreview(cameraController) : Center(child: CircularProgressIndicator()),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                      onPressed: (){},
                      icon: Icon(CupertinoIcons.photo, color: Colors.white, size: 35)
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      if (_isRecording) {
                        await _stopVideoRecording();
                      } else {
                        await _startVideoRecording();
                      }
                      setState(() {
                        _isRecording = !_isRecording;
                      });
                    },
                    icon: Icon(
                      _isRecording ? CupertinoIcons.stop_circle : CupertinoIcons.circle_fill,
                      color: _isRecording? Colors.red : Colors.white,
                      size: 35,
                    ),
                  ),
                  AnimatedBuilder(
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
                ]
              )
            ),
          )
        ]
      )
    );
  }

  Widget lastInterpretedWidget(String text) {
    return Card(
      child: ListTile(
        title: Text("Last Interpreted"),
        subtitle: Text(
          text,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget recentTranslationsWidget(List<String> words) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text("Recent Translations"),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: words
                  .map((word) => Chip(label: Text(word)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            cameraWidget(controller),
            const SizedBox(height: 20),
            lastInterpretedWidget("Hello"),
            const SizedBox(height: 20),
            recentTranslationsWidget(["Hello", "My", "Name", "Is", "Juan"]),
          ],
        ),
      ),
    );
  }
}