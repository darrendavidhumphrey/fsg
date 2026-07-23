import 'package:flutter/cupertino.dart';

// The example scenes are placed in an IndexedStackScene that corresponds
// with the IndexedStack flutter widget to draw only one example scene
// at a time.
class ExtendedExampleScenes extends StatefulWidget {
  final int extendedSceneIndex;
  const ExtendedExampleScenes({super.key, required this.extendedSceneIndex});
  @override
  ExtendedExampleScenesState createState() => ExtendedExampleScenesState();

  static List<String> menuLabels = [
    'Multiple Scenes',
        'Second Scene',
    'Third Scene',
  ];
}

class ExtendedExampleScenesState extends State<ExtendedExampleScenes> {
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
        index: widget.extendedSceneIndex,
        children: const [
          Center(child: Text('Multiple Views Scene')),
          Center(child: Text('Second Scene')),
          Center(child: Text('Third Scene')),
        ],
    );
  }

}
