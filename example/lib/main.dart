import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fsg/fsg.dart';
import 'package:flutter/material.dart';
import 'package:fsg_examples/example_scenes.dart';

void main() async {
  Logging.brevity = Brevity.detailed;
  Logging.defaultLogLevel = LogLevel.pedantic;
  if (!kDebugMode) {
    Logging.setConsoleLogFunction(null);
  }

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(TestApp());
}

class TestApp extends StatefulWidget {
  const TestApp({super.key});

  @override
  TestAppState createState() => TestAppState();
}

class TestAppState extends State<TestApp> {
  int _pageIndex = 0;
  ExampleScenes? scene;

  Future<void> initAngle() async {
    // Override the size of the render to texture buffer here (defaults to 4096)
    // FSG.renderToTextureSize = 1024;

    // Initialize FSG. This call immediately sets FSG().state to inProgress
    await FSG().initPlatformState();

    // Create the scene
    scene = ExampleScenes();

    // Register the scene and allocate a texture
    await FSG().registerSceneAndAllocateTexture(scene!);

    // Trigger a rebuild of the widget
    setState(() {});
  }

  static final List<DropdownMenuEntry<int>> menuEntries = [
    DropdownMenuEntry(value: 0, label: 'Example 1: Checkerboard Shaded Quad'),
    DropdownMenuEntry(value: 1, label: 'Example 2: Animated Shader Uniforms'),
    DropdownMenuEntry(value: 2, label: 'Example 3: Navigation Delegate)',),
    DropdownMenuEntry(value: 3, label: 'Example 4: Bitmap Text',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (FSG().state == FsgState.uninitialized) {
          initAngle();
        }

        if (scene == null) {
          return const CircularProgressIndicator();
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: MaterialApp(
            title: 'FSG Examples',
             //showPerformanceOverlay: true,
            home: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        RenderToTexture(
                          scene: scene!.currentScene(),
                          navigationDelegate: scene!.currentDelegate(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: DropdownMenu<int>(
                            initialSelection: _pageIndex,
                            label: const Text('Select Example'),
                            onSelected: (int? value) {
                              setState(() {
                                _pageIndex = value!;
                                scene!.setCurrentScene(_pageIndex);
                              });
                            },
                            dropdownMenuEntries: menuEntries,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
