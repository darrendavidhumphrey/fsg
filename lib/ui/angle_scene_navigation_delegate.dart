import 'package:flutter/gestures.dart';
import '../gl_common/angle_scene.dart';

abstract class AngleSceneNavigationDelegate {

  void setScene(AngleScene scene);

  void onTapDown(TapDownDetails event);
  void onPointerDown(PointerDownEvent event);
  void onPointerMove(PointerMoveEvent event);
  void onPointerScroll(PointerScrollEvent event);
}