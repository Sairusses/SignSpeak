import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(
        cameras![1], // front or back camera depending on your use case
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
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
                  IconButton.filled(
                      onPressed: (){},
                      icon: Icon(CupertinoIcons.photo, color: Colors.white, size: 35)
                  ),
                  IconButton.filled(
                      onPressed: (){},
                      icon: Icon(CupertinoIcons.circle_fill, color: Colors.white, size: 35)
                  ),
                  IconButton.filled(
                      onPressed: (){},
                      icon: Icon(CupertinoIcons.switch_camera_solid, color: Colors.white, size: 35)
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