import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:fsk/fsk.dart';
import 'package:fsk/ui/navigation_delegates/scene_navigation_delegate.dart';
import 'package:vector_math/vector_math_64.dart';

/// A navigation delegate that implements a static orthographic view
class OrthoViewDelegate extends FskSceneNavigationDelegate implements ScreenRectSubscriber {
  static const Rect defaultViewRect = Rect.fromLTWH(0, 0, 250, 250);
  OrthoViewDelegate({this._viewRect=defaultViewRect});

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

  @override
  void setViewRect(Rect value) {
    _viewRect = value;
    setNeedsUpdate(true);
  }

  // --- Getters ---
  double get zNear => _zNear;
  double get zFar => _zFar;

  @override
  Matrix4 createViewMatrix() {
    // Fill the render area with the content
    var view = Matrix4.identity();
    return view;
  }

  @override
  Matrix4 createProjectionMatrix() {
    Matrix4 proj = Matrix4.identity();

    // Web and Android require Y-UP orientation for this ortho view, 
    // while Desktop/iOS use Y-DOWN to match Flutter's coordinate system.
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      setOrthographicMatrix(
          proj,
          _viewRect.left,
          _viewRect.right,
          _viewRect.top, // Maps to -1 (bottom of NDC)
          _viewRect.bottom, // Maps to 1 (top of NDC)
          _zNear,
          _zFar);
    } else {
      setOrthographicMatrix(
          proj,
          _viewRect.left,
          _viewRect.right,
          _viewRect.bottom, // Maps to -1 (bottom of NDC)
          _viewRect.top, // Maps to 1 (top of NDC)
          _zNear,
          _zFar);
    }

    return proj;
  }
}
