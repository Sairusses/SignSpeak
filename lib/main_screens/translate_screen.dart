import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TranslateScreen extends StatefulWidget {
  final CameraController cameraController;
  final bool isCameraInitialized;
  const TranslateScreen({super.key, required this.cameraController, required this.isCameraInitialized});

  @override
  TranslateScreenState createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {
  get cameraController => widget.cameraController;
  get isCameraInitialized => widget.isCameraInitialized;
  bool _isRecording = false;
  String _translatedText = "Translated text will appear here...";

  @override
  void initState() {
    super.initState();
  }



  Future<void> _startRecording() async {
    if (!_isRecording) {
      await cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      final file = await cameraController.stopVideoRecording();
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
    cameraController.dispose();
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
            child: isCameraInitialized
                ? CameraPreview(cameraController)
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
                  color: Colors.black.withAlpha(75),
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
