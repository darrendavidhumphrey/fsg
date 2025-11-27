import 'package:flutter_angle_jig/ui/navigation_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle_jig/gl_common/flutter_angle_manager.dart';
import 'package:flutter_angle_jig/logging.dart';
import 'package:flutter_angle_jig/ui/orbit_view_delegate.dart';
import 'simple_example_canvas.dart';

void main() async {
  Logging.logLevel = LogLevel.pedantic;
  Logging.brevity = Brevity.detailed;
  Logging.setConsoleLogFunction((String message) {
    if (kDebugMode) {
      print(message);
    }
  });

  WidgetsFlutterBinding.ensureInitialized();
  runApp(TestApp());
}

class TestApp extends StatelessWidget {

  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scene = SimpleExampleCanvas();
    final OrbitView orbitView = OrbitView();

    final OrbitView orbitView2 = OrbitView();
    final scene2 = SimpleExampleCanvas();
    FlutterAngleManager().initPlatformState(context, scene);
    FlutterAngleManager().allocTextureForScene(scene2);
    return MaterialApp(
        title: 'test',
        home: Stack(
          children: [

            Positioned(
              left: 0,
              child: SizedBox(
                width: 500,
                  height: 500,
                  child: NavigationWidget(navigationDelegate: orbitView, scene: scene)),
            ),
            Positioned(
              left: 500,
              child: SizedBox(
                  width: 500,
                  height: 500,
                  child: NavigationWidget(navigationDelegate: orbitView2, scene: scene2)),
            ),
          ],
        )
    );
  }
}

