import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  TranslateScreenState createState() => TranslateScreenState();
}

class TranslateScreenState extends State<TranslateScreen> {

  @override
  Widget build(BuildContext context) {

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
          CameraAwesomeBuilder.awesome(
            saveConfig: SaveConfig.video(),
            sensorConfig: SensorConfig.single(
              aspectRatio: CameraAspectRatios.ratio_4_3,
              flashMode: FlashMode.auto,
              sensor: Sensor.position(SensorPosition.back),
              zoom: 0.0,
            ),
          )
        ],
      ),
    );
  }
}
