import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../scene.dart';

/// An abstract interface for classes that handle user input to navigate a [Scene].
///
/// This decouples the interaction logic (like orbiting, panning, or zooming)
/// from the rendering widget itself. It defines a contract for a set of event
/// handlers that a widget like [RenderToTexture] can call in response to user input.
abstract class SceneNavigationDelegate {
  /// The scene that this delegate controls.
  late Scene scene;
  final Matrix4 projectionMatrix = Matrix4.identity();
  final Matrix4 viewMatrix = Matrix4.identity();

  void createViewMatrix();
  void createProjectionMatrix();

  void updateSceneMatrices() {

    if (scene.isInitialized) {
      createViewMatrix();
      scene.mvMatrixStack.current = viewMatrix;

      createProjectionMatrix();
      scene.pMatrix = projectionMatrix;
      scene.requestRepaint();
    }
    scene.requestRepaint();
  }

  /// Sets the scene that this delegate will control. This is typically called
  /// by the owner widget when the delegate is initialized or when the scene changes.
  void setScene(Scene scene) {
    this.scene = scene;
    updateSceneMatrices();
  }

  /// Called when a tap down event occurs. Useful for discrete actions like
  /// object selection or setting a focus point.
  void onTapDown(TapDownDetails event){}

  /// Called when a pointer makes contact with the screen. This is typically
  /// the start of a continuous gesture like a drag or pan.
  void onPointerDown(PointerDownEvent event){}

  /// Called when a pointer that is in contact with the screen has moved.
  /// This is used to update continuous gestures.
  void onPointerMove(PointerMoveEvent event){}

  /// Called when a pointer that is in contact with the screen is no longer
  /// in contact. This signals the end of a continuous gesture.
  void onPointerUp(PointerUpEvent event){}

  /// Called when the input from a pointer is no longer directed at this widget,
  /// for example, if the system cancels the gesture.
  void onPointerCancel(PointerCancelEvent event){}

  /// Called when a pointer scroll event occurs (e.g., mouse wheel or trackpad scroll).
  /// This is typically used for zooming or dollying the camera.
  void onPointerScroll(PointerScrollEvent event){}

  /// Handles a key event from a focused widget.
  ///
  /// Returns a [KeyEventResult] to indicate whether the event was handled.
  KeyEventResult onKeyEvent(KeyEvent event){
    return KeyEventResult.ignored;
  }

  void dispose();
}
