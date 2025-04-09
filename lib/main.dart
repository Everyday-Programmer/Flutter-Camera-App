import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(CameraApp());
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData.dark(),
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  int selectedCameraIndex = 0;
  bool isInitialized = false;
  bool permissionGranted = false;

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      permissionGranted = true;
      initializeCamera(selectedCameraIndex);
    } else {
      setState(() {
        permissionGranted = false;
      });
    }
  }

  void initializeCamera(int index) async {
    controller = CameraController(
      cameras[index],
      ResolutionPreset.medium,
    );

    try {
      await controller.initialize();
      setState(() {
        isInitialized = true;
        selectedCameraIndex = index;
      });
    } catch (e) {
      print('Camera error: $e');
    }
  }

  void switchCamera() async {
    final newIndex = (selectedCameraIndex + 1) % cameras.length;

    setState(() {
      isInitialized = false;
    });

    await controller.dispose();

    initializeCamera(newIndex);
  }

  Future<void> takePicture(BuildContext context) async {
    if (!controller.value.isInitialized) return;

    final directory = Directory('/storage/emulated/0/Pictures/CameraApp');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = join(directory.path, 'IMG_$timestamp.png');
    await File(path).create(recursive: true);

    try {
      await controller.takePicture().then((file) {
        file.saveTo(path);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisplayPictureScreen(imagePath: path),
          ),
        );
      });
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    if (controller.value.isInitialized) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!permissionGranted) {
      return Scaffold(
        body: Center(
          child: Text("Camera permission is required."),
        ),
      );
    }

    if (!isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Camera App'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera_rounded),
            onPressed: switchCamera,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox.expand(
              child: CameraPreview(controller),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: IconButton(
                  icon: Icon(Icons.camera, size: 80, color: Colors.white),
                  onPressed: () => takePicture(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Captured Image')),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}
