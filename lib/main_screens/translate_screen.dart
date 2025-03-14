import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  _TranslateScreenState createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  String _translatedText = "Translated text will appear here...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras[0], // Use the first available camera
        ResolutionPreset.medium,
      );

      await _cameraController.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecording) {
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _translatedText = "Processing video..."; // Simulated processing
      });

      // TODO: Process video and update translated text
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _translatedText = "Hello, how are you?"; // Simulated translation result
        });
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Camera Preview (60% of screen)
          SizedBox(
            height: screenHeight * 0.6,
            width: double.infinity,
            child: _isCameraInitialized
                ? CameraPreview(_cameraController)
                : const Center(child: CircularProgressIndicator()),
          ),

          // Translated Text Display (20% of screen)
          Container(
            height: screenHeight * 0.2,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _translatedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),

      // Floating record button
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        backgroundColor: _isRecording ? Colors.red : Colors.blue,
        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
