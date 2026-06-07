import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/fsg.dart';

// IndexedStackScene contains a list of scenes and a current scene index.
// Only the current scene is rendered. Its behavior is analogous to the
// IndexedStack widget in flutter
class IndexedStackScene extends Scene {
  Scene? _currentScene;
  final List<Scene> scenes = [];
  final Map<Scene, SceneNavigationDelegate> delegates = {};
  int _currentIndex = 0;
  IndexedStackScene();

  @override
  @mustCallSuper
  void init(RenderingContext gl) {
    super.init(gl);
  }

  // Add a scene to the list of scenes, optionally with a delegate.
  void addScene(Scene scene,{SceneNavigationDelegate? delegate}) {
    scene.init(gl);
    FSG().reuseTexture(renderToTextureId!, scene);
    scenes.add(scene);
    if (delegate != null) {
      delegates[scene] = delegate;
    }
  }

  void setCurrentScene(int index) {
    if (index < scenes.length) {
      _currentScene = scenes[index];
      _currentIndex = index;
      requestRepaint();
    }
  }

  @override
  void setViewportSize(Size size) {
    super.setViewportSize(size);
    for (var scene in scenes) {
      scene.setViewportSize(size);
    }
  }

  Scene currentScene() {
    if (scenes.length > _currentIndex) {
      return scenes[_currentIndex];
    }
    return this;
  }

  SceneNavigationDelegate? currentDelegate() {
    if (scenes.length > _currentIndex) {
      return delegates[scenes[_currentIndex]];
    }
    return null;
  }

  @override
  void dispose() {}

  @override
  void drawScene() {
    super.drawScene();

    if (_currentScene != null) {
      _currentScene!.drawScene();
      _currentScene!.requestRepaint();
      requestRepaint();
    }
  }
}
