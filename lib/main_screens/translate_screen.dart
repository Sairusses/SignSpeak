import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  TranslateScreenState createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SignSpeak'),
        centerTitle: true,
        leading: IconButton(onPressed: (){}, icon: Icon(Icons.flash_on)),
        actions: [
          IconButton(onPressed: (){}, icon: Icon(Icons.settings))
        ],
      ),
      body: Column(
        children: [
          CameraPreviewWidget()
        ],
      ),
    );
  }
}

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({super.key});
  @override
  CameraPreviewWidgetState createState() => CameraPreviewWidgetState();
}

class CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );

      await _cameraController.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.5,
          width: screenWidth,
          child:
          // _isCameraInitialized
          //     ? CameraPreview(_cameraController) :
          Container(
            color: Colors.black,
            height: screenHeight * 0.5,
            width: screenWidth,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  // Handle import video
                  print('Import video pressed');
                },
                icon: Icon(Icons.video_library),
                iconSize: 40,
              ),
              SizedBox(width: 32),
              IconButton(
                onPressed: (){},
                icon: Icon(_isRecording ? Icons.stop_circle : Icons.circle),
                color: _isRecording ? Colors.red : Colors.white,
                iconSize: 60,
              ),
              SizedBox(width: 32),
              IconButton(
                onPressed: (){},
                icon: Icon(Icons.flip_camera_ios),
                iconSize: 40,
              ),
            ],
          ),
        ),
      ],
    );
  }
}