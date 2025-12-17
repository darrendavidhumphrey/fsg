import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';
import '../gl_common/scene.dart';
import '../gl_common/util.dart';
import '../util.dart';
import 'angle_scene_navigation_delegate.dart';

class OrbitView implements AngleSceneNavigationDelegate {
  static const double _initialYaw = 0;
  static const double _initialPitch = 0;

  final double verticalFieldOfView = radians(60);

  double _yaw = _initialYaw;

  double get yaw => _yaw;

  double _pitch = _initialPitch;

  double get pitch => _pitch;

  double _distance = 300;

  double get distance => _distance;

  Offset _dragStart = Offset.zero;
  double _yawStart = 0;
  double _pitchStart = 0;

  Plane _projectPlane = Plane();

  final Matrix4 _projectionMatrix = Matrix4.identity();
  Matrix4 _viewMatrix = Matrix4.identity();

  Scene? scene;


  OrbitView() {
    _projectPlane = makePlaneFromVertices(
      Vector3.zero(),
      Vector3(1, 0, 0),
      Vector3(0, 1, 0),
    )!;
  }

  double _clampAngle0To360(double angle) {
    // Normalize to be within 0 and 360 using modulo
    double clamped = angle % 360;

    // If the result is negative, add 360 to bring it into the positive range
    if (clamped < 0) {
      clamped += 360;
    } else if (clamped > 360) {
      clamped -= 360;
    }
    return clamped;
  }

  void updateSceneMatrices() {
    if (scene != null) {
      scene!.mvMatrix = createViewMatrix();
      scene!.pMatrix = createProjectionMatrix();
    }
  }

  @override
  void setScene(Scene scene) {
    this.scene = scene;
    updateSceneMatrices();
  }

  @override
  void onPointerDown(PointerDownEvent event) {
    print("onPointerDown");
    _dragStart = event.localPosition;
    _yawStart = yaw;
    _pitchStart = pitch;
    updateSceneMatrices();
  }

  @override
  void onTapDown(TapDownDetails event) {
    _dragStart = event.localPosition;
    _yawStart = yaw;
    _pitchStart = pitch;
    updateSceneMatrices();
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    final deltaX = _dragStart.dx - event.localPosition.dx;
    final deltaY = _dragStart.dy - event.localPosition.dy;

    final double yawSensitivity = 1 / scene!.viewportSize.width;
    final double pitchSensitivity = 1 / scene!.viewportSize.height;
    final double deltaYaw = deltaX * yawSensitivity * pi;
    final double deltaPitch = deltaY * pitchSensitivity * pi;

    final newYaw = _yawStart + degrees(deltaYaw);
    final newPitch = _pitchStart + degrees(deltaPitch);

    _yaw = _clampAngle0To360(newYaw);
    _pitch = _clampAngle0To360(newPitch);
    updateSceneMatrices();
  }

  @override
  void onPointerScroll(PointerScrollEvent event) {
    const double minRadius = 3;

    double viewRadius = distance;

    double deltaRadius = -log(distance) / log(2);

    if (event.scrollDelta.dy < 0) {
      deltaRadius = -deltaRadius;
    }

    viewRadius += deltaRadius;

    if (viewRadius < minRadius) {
      viewRadius = minRadius;
    }
    setViewDistance(viewRadius);
    updateSceneMatrices();
  }

  void setViewDistance(double distance) {
    _distance = distance;
  }

  Matrix4 createViewMatrix() {
    Vector3 up = Vector3(0, 1, 0);
    Vector3 orbitCenter = getOrbitCenter();


    _viewMatrix = createLookAtMatrix(getEyeLocation(), orbitCenter, up);
    _viewMatrix.translateByVector3(orbitCenter);
    _viewMatrix.rotateZ(radians(180));
    _viewMatrix.rotateY(radians(yaw));
    _viewMatrix.rotateX(radians(pitch));
    _viewMatrix.translateByVector3(-orbitCenter);
    return _viewMatrix;
  }

  Vector3 getEyeLocation() {
    return Vector3(0, 0, -distance);
  }

  Vector3 getOrbitCenter() {
    return Vector3(0,0,0);
  }

  Vector3 getLogicalCoordinates(Offset mousePosition) {
    Ray ray = computePickRay(
      mousePosition,
      scene!.viewportSize,
      _projectionMatrix,
      _viewMatrix,
    );
    return intersectRayWithPlane(ray, _projectPlane);
  }

  Ray getWorldRay(Offset mousePosition) {
    Ray ray = computePickRay(
      mousePosition,
      scene!.viewportSize,
      _projectionMatrix,
      _viewMatrix,
    );
    return ray;
  }

  Matrix4 createProjectionMatrix() {
    final double aspectRatio = scene!.viewportSize.width / scene!.viewportSize.height;

    setPerspectiveMatrix(
      _projectionMatrix,
      verticalFieldOfView,
      aspectRatio,
      0.1,
      5000000,
    );

    return _projectionMatrix;
  }
}