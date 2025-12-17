import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import '../logging.dart';
import 'scene_layer.dart';

abstract class ScreenSpaceOverlay extends SceneLayer with LoggableClass {
  final double textureSize;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Size screenSpaceSize;
  ScreenSpaceOverlay({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.screenSpaceSize,
    required this.textureSize,
  }) {
    // User must set one and only one of left and right
    assert(!(left == null && bottom == right));
    if (left != null) {
      assert(right == null);
    } else if (right != null) {
      assert(left == null);
    }

    // User must set one and only one of top and bottom
    assert(!(top == null && bottom == null));
    if (top != null) {
      assert(bottom == null);
    } else if (bottom != null) {
      assert(top == null);
    }
  }

  Offset screenToViewport(Offset screen) {
    double x = screen.dx;
    double y = screen.dy;
    if (left != null) {
      x = x - left!;
    } else if (right != null) {
      double leftEdge = viewportSize.width - screenSpaceSize.width - right!;
      x -= leftEdge;
    }
    if (top != null) {
      y = y - top!;
    } else if (bottom != null) {
      double bottomEdge =
          viewportSize.height - screenSpaceSize.height - bottom!;
      y = y - bottomEdge;
    }
    return Offset(x, y);
  }

  bool isPointInViewport(Offset point) {
    Offset viewportRelative = screenToViewport(point);
    bool result =
        viewportRelative.dx >= 0 &&
        viewportRelative.dx <= viewportSize.width &&
        viewportRelative.dy >= 0 &&
        viewportRelative.dy <= viewportSize.height;

    return result;
  }

  double textureToScreenX(double x) {
    return (x / viewportSize.width.toDouble()) * textureSize;
  }

  double textureToScreenY(double y) {
    return (y / viewportSize.height.toDouble()) * textureSize;
  }

  void enableScissor() {
    double windowWidth = textureToScreenX(screenSpaceSize.width);
    double windowHeight = textureToScreenY(screenSpaceSize.height);

    double startX = 0;
    if (right != null) {
      startX = textureToScreenX(
        viewportSize.width - screenSpaceSize.width - right!,
      );
    } else if (left != null) {
      startX = textureToScreenX(left!);
    }

    double startY = 0;
    if (bottom != null) {
      startY = textureToScreenY(
        viewportSize.height - screenSpaceSize.height - bottom!,
      );
    } else if (top != null) {
      startY = textureToScreenY(top!);
    }

    gl.enable(WebGL.SCISSOR_TEST);
    gl.scissor(
      startX.toInt(),
      startY.toInt(),
      windowWidth.toInt(),
      windowHeight.toInt(),
    );
    gl.viewport(
      startX.toInt(),
      startY.toInt(),
      windowWidth.toInt(),
      windowHeight.toInt(),
    );
  }
}
