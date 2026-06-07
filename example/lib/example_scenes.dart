import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/fsg.dart';
import 'package:fsg/indexed_stack_scene.dart';
import 'package:fsg_examples/animated_checkerboard_scene.dart';
import 'package:fsg_examples/bitmap_text_scene.dart';
import 'package:fsg_examples/orbitview_scene.dart';
import 'checkerboard_scene.dart';

// The example scenes are placed in an IndexedStackScene that corresponds
// with the IndexedStack flutter widget to draw only one example scene
// at a time.
class ExampleScenes extends IndexedStackScene {

  ExampleScenes();

  @override
  void init(RenderingContext gl) {
    super.init(gl);

    addScene(CheckerBoardScene());
    addScene(AnimatedCheckerBoardScene());
    addScene(OrbitViewScene(),delegate: OrbitView());
    addScene(BitmapTextScene(),delegate:OrbitView());

    setCurrentScene(0);
  }
}
