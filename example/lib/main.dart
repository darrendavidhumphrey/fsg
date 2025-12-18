import 'package:flutter/services.dart';
import 'package:fsg/fsg.dart';
import 'package:flutter/material.dart';
import 'example1_scene.dart';

void main() async {
  Logging.brevity = Brevity.detailed;
  Logging.displayUnfilteredLogs = false;
  Logging.setConsoleLogFunction((String message) {
    print(message);
  });
  Logging.setLogLevel(LogLevel.pedantic,  "CheckerBoardShader");

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

  late Example1Scene scene0;
  late OrbitView orbitView;
  @override
  void initState() {
    super.initState();
    scene0 = Example1Scene();
    orbitView = OrbitView();
    // FlutterAngleJig.renderToTextureSize = 1024;
    FSG().allocTextureForScene(scene0);

  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'test',
      home: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _pageIndex,
              children: [
                InteractiveRenderToTexture(
                  navigationDelegate: orbitView,
                  scene: scene0,
                ),
                Container(decoration: BoxDecoration(color: Colors.blue)),
                Container(decoration: BoxDecoration(color: Colors.green)),
              ],
            ),

            Positioned(
              bottom: 0,
              child: DropdownMenu<int>(
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
                    label: 'Example 1',
                  ),
                  DropdownMenuEntry(
                    value: 1,
                    label: 'Blue',
                  ),
                  DropdownMenuEntry(
                    value: 2,
                    label: 'Green',
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
