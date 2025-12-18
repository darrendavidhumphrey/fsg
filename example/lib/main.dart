import 'package:flutter/services.dart';
import 'package:fsg/fsg.dart';
import 'package:flutter/material.dart';
import 'checkerboard_scene.dart';
import 'checkerboard_uniforms_scene.dart';

void main() async {
  Logging.brevity = Brevity.detailed;
  Logging.defaultLogLevel = LogLevel.verbose;
  Logging.setConsoleLogFunction((String message) {
    print(message);
  });

  WidgetsFlutterBinding.ensureInitialized();
  FSG().initPlatformState();

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

  late CheckerBoardScene checkerBoardScene;

  @override
  void initState() {
    super.initState();
    checkerBoardScene = CheckerBoardScene();
    FSG().registerSceneAndAllocateTexture(checkerBoardScene);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSG Examples',
     // showPerformanceOverlay: true,
      home: Scaffold(
        body: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _pageIndex,
                    children: [
                      RenderToTexture(scene: checkerBoardScene),
                      CheckerBoardUniformsExample(),
                      Container(decoration: BoxDecoration(color: Colors.green)),
                    ],
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: const EdgeInsets.only(top:8.0,left:8.0,right:8.0),
                        child: DropdownMenu<int>(
                          width: constraints.maxWidth,
                          initialSelection: _pageIndex,
                          label: const Text('Select Example'),
                          // onSelected is called when the user picks an item
                          onSelected: (int? value) {
                            setState(() {
                              _pageIndex = value!;
                            });
                          },
                          // Define the entries in the menu
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(
                              value: 0,
                              label: 'Example 1: Hello World',
                            ),
                            DropdownMenuEntry(
                              value: 1,
                              label: 'Example 2: Driving Shader Uniforms',
                            ),
                            DropdownMenuEntry(value: 2, label: 'Green'),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
