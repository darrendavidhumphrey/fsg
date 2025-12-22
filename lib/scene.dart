import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/performance_monitor.dart';
import 'logging.dart';
import 'fsg_singleton.dart';
import 'scene_layer.dart';

abstract class Scene with LoggableClass {
  late RenderingContext gl;
  /// Perspective matrix
  Matrix4 pMatrix = Matrix4.identity();

  /// Model-View matrix.
  Matrix4 mvMatrix = Matrix4.identity();

  final List<SceneLayer> layers =[];
  final List<Matrix4> mvStack = <Matrix4>[];
  late final PerformanceMonitor performanceMonitor;
  bool _needsRepaint = true;
  Size _viewportSize = Size.zero;
  Size get viewportSize => _viewportSize;


  FlutterAngleTexture? renderToTextureId;
  bool isPaused = false;
  bool isInitialized = false;

  Scene() {
    print("Scene constructor and class name is ${runtimeType.toString()}");
    performanceMonitor = PerformanceMonitor(tag: runtimeType.toString());
  }


  /// Add a copy of the current Model-View matrix to the the stack for future
  /// restoration.
  void _mvPushMatrix() => mvStack.add(Matrix4.copy(mvMatrix));

  /// Pop the last matrix off the stack and set the Model View matrix.
  void _mvPopMatrix() => mvMatrix = mvStack.removeLast();

  void withPushedMatrix(void Function() drawCommands) {
    _mvPushMatrix();
    try {
      drawCommands();
    } finally {
      _mvPopMatrix();
    }
  }

  int get textureWidth => FSG.renderToTextureSize.toInt();
  int get textureHeight => FSG.renderToTextureSize.toInt();

  void init(RenderingContext gl) {
    this.gl = gl;
    FSG().initContext(gl);
    mvMatrix = Matrix4.identity();
    gl.clearColor(0, 1, 0, 1);
    isInitialized = true;
  }

  void requestRepaint() {
    _needsRepaint = true;
  }

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

  void addLayer(SceneLayer layer) {
    layers.add(layer);
    layer.parent = this;
  }

  void rebuildLayers(RenderingContext gl,DateTime now) {
    for (SceneLayer layer in layers) {
      layer.rebuild(gl,now);
    }
  }
  void drawLayers() {
    for (SceneLayer layer in layers) {
      layer.draw(pMatrix, mvMatrix);
    }
  }

  bool needsRebuild() {
    for (SceneLayer layer in layers) {
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

    if (isPaused) {
      return;
    }

    if (_needsRepaint ||  needsRebuild()) {
      // Set to false at start of loop so drawScene() can re-enable it if desired
      _needsRepaint = false;

      renderToTextureId!.activate();
      performanceMonitor.beginFrame();
      drawScene();
      await renderToTextureId!.signalNewFrameAvailable();
      performanceMonitor.endFrame();
    }
  }
}
