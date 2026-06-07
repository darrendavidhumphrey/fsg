import 'package:fsg/ui/navigation_delegates/scene_navigation_delegate.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../fsg_singleton.dart';

/// A navigation delegate that implements a static view
class StaticViewDelegate extends SceneNavigationDelegate {
  StaticViewDelegate();

  @override
  void createViewMatrix() {
    Vector3 up = Vector3(0, 1, 0);
    Vector3 orbitCenter = Vector3(0, 0, 0);
    Vector3 eyeLocation = Vector3(0, 0, -500);

    Matrix4 m = makeViewMatrix(eyeLocation, orbitCenter, up);
    m.translateByVector3(orbitCenter);
    m.rotateZ(radians(180));
    m.rotateY(radians(0));
    m.rotateX(radians(45));
    m.translateByVector3(-orbitCenter);
    m.copyInto(viewMatrix);
  }

  @override
  void createProjectionMatrix() {
    final double aspectRatio =
        scene.viewportSize.width / scene.viewportSize.height;

    Matrix4 proj = Matrix4.identity();
    setPerspectiveMatrix(proj, radians(60), aspectRatio, 0.1, 5000000);

    // Ensure Y Axis is the same regardless of platform
    FSG.normalizeUpAxis(proj);
    proj.copyInto(projectionMatrix);
  }

  @override
  void dispose() {
    // No resources to dispose of in this specific implementation.
  }
}
