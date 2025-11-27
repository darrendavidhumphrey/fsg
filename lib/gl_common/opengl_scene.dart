import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import '../logging.dart';
import 'flutter_angle_manager.dart';
import 'opengl_scene_layer.dart';

abstract class OpenGLScene with LoggableClass {
  late RenderingContext gl;
  /// Perspective matrix
  late Matrix4 pMatrix;

  /// Model-View matrix.
  late Matrix4 mvMatrix;

  final List<OpenGLSceneLayer> layers =[];
  List<Matrix4> mvStack = <Matrix4>[];
  OpenGLScene();

  bool forceRepaint = true;
  FlutterAngleTexture? renderToTextureId;
  bool isInitialized = false;

  final Stopwatch stopwatch = Stopwatch();
  int frameCount=0;
  int totalMicroseconds=0;
  bool timingEnabled = true;


  int textureWidth() {
    return FlutterAngleManager.renderToTextureSize.toInt();
  }
  int textureHeight() {
    return FlutterAngleManager.renderToTextureSize.toInt();
  }

  void init(BuildContext context, RenderingContext gl) {
    this.gl = gl;
    mvMatrix = Matrix4.identity();
    gl.clearColor(0, 1, 0, 1);
    isInitialized = true;
  }

  Size _viewportSize = Size.zero;
  Size get viewportSize => _viewportSize;

  void setViewportSize(Size size) {
    logPedantic("setViewportSize: ${size.toString()}");
    _viewportSize = size;
    for (var layer in layers) {
      layer.setViewportSize(size);
    }
  }

  /// Render the scene to the [viewWidth], [viewHeight], and [aspect] ratio.
  void drawScene();

  void dispose() {}

  /// Add a copy of the current Model-View matrix to the the stack for future
  /// restoration.
  void mvPushMatrix() => mvStack.add(Matrix4.copy(mvMatrix));

  /// Pop the last matrix off the stack and set the Model View matrix.
  void mvPopMatrix() => mvMatrix = mvStack.removeLast();

  void addLayer(OpenGLSceneLayer layer) {
    layers.add(layer);
    layer.parent = this;
  }

  void rebuildLayers(RenderingContext gl,DateTime now) {
    for (OpenGLSceneLayer layer in layers) {
      layer.rebuild(gl,now);
    }
  }
  void drawLayers() {
    for (OpenGLSceneLayer layer in layers) {
      layer.draw(pMatrix, mvMatrix);
    }
  }

  bool needsRebuild() {
    for (OpenGLSceneLayer layer in layers) {
      if (layer.needsRebuild) {
        return true;
      }
    }
    return false;
  }

  Future<void> renderSceneToTexture(_) async {

    if (renderToTextureId == null) {
      return;
    }

    // TODO: Repaint is forced to always on
    forceRepaint = true;
    if (timingEnabled || forceRepaint ||  needsRebuild()) {

      if (timingEnabled) {
        stopwatch..reset()..start();
      }
      renderToTextureId!.activate();

      drawScene();
      await renderToTextureId!.signalNewFrameAvailable();

      if (timingEnabled) {
        totalMicroseconds += stopwatch.elapsedMicroseconds;
        frameCount++;

        if (frameCount==100) {
          double averageMilliseconds = (totalMicroseconds/frameCount)/1000.0;
          logPedantic("Avg draw time: ${averageMilliseconds.toStringAsFixed(2)} ms");
          frameCount = 0;
          totalMicroseconds = 0;
        }
      }
      forceRepaint = false;
    }
  }


}
