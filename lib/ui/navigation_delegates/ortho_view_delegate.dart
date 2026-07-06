import 'dart:ui';

import 'package:fsg/ui/navigation_delegates/scene_navigation_delegate.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../fsk_singleton.dart';

/// A navigation delegate that implements a static orthographic view
class OrthoViewDelegate extends SceneNavigationDelegate {
  OrthoViewDelegate({required this._viewRect});

  Rect _viewRect;
  double _zNear = -1000;
  double _zFar = 1000;


  set zNear(double value) {
    if (_zNear == value) return;
    _zNear = value;
    setNeedsUpdate(true);
  }

  set zFar(double value) {
    if (_zFar == value) return;
    _zFar = value;
    setNeedsUpdate(true);
  }

  set viewRect(Rect value) {
    _viewRect = value;
    setNeedsUpdate(true);
  }

  // --- Getters ---
  double get zNear => _zNear;
  double get zFar => _zFar;

  @override
  Matrix4 createViewMatrix() {
    // Fill the render area with the content
    return Matrix4.identity();
  }

  @override
  Matrix4 createProjectionMatrix() {
    Matrix4 proj = Matrix4.identity();
    setOrthographicMatrix(proj, _viewRect.left, _viewRect.right, _viewRect.bottom, _viewRect.top, _zNear, _zFar);

    // Ensure Y Axis is the same regardless of platform
    FSK.normalizeUpAxis(proj);

    return proj;
  }
}
