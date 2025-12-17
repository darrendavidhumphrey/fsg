import 'package:flutter_angle_jig/fsg.dart';
import 'package:flutter/material.dart';
import 'simple_example_canvas.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FSG().initPlatformState();
  runApp(TestApp());
}

class TestApp extends StatelessWidget {

  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scene = SimpleExampleCanvas();
    final OrbitView orbitView = OrbitView();
   // FlutterAngleJig.renderToTextureSize = 1024;
    FSG().allocTextureForScene(scene);

    return MaterialApp(
        title: 'test',
        home: InteractiveRenderToTexture(navigationDelegate: orbitView, scene: scene)
    );
  }
}

