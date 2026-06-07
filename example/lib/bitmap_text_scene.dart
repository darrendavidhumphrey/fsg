import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/fsg.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class BitmapTextScene extends Scene {

  BitmapTextScene();

  List<BitmapText> textItems = [];

  @override
  void init(RenderingContext gl) {
    super.init(gl);

    // TOOD: Create text and load fonts
  }

  @override
  void dispose() {}

  void createViewMatrix() {
    Vector3 up = Vector3(0, 1, 0);
    Vector3 orbitCenter = Vector3(0,0,0);
    Vector3 eyeLocation = Vector3(0,0,-500);

    mvMatrixStack.current = makeViewMatrix(eyeLocation, orbitCenter, up);
    mvMatrix.translateByVector3(orbitCenter);
    mvMatrix.rotateZ(radians(180));
    mvMatrix.rotateY(radians(0));
    mvMatrix.rotateX(radians(45));
    mvMatrix.translateByVector3(-orbitCenter);
  }

  void createProjectionMatrix() {
    final double aspectRatio = viewportSize.width / viewportSize.height;

    setPerspectiveMatrix(
      pMatrix,
      radians(60),
      aspectRatio,
      0.1,
      5000000,
    );

    // Ensure Y Axis is the same regardless of platform
    FSG.normalizeUpAxis(pMatrix);
  }

  void updateTextItems() {

  }

  @override
  void drawScene() {
    super.drawScene();

    updateTextItems();
    gl.viewport(0, 0, FSG.renderToTextureSize.toInt(), FSG.renderToTextureSize.toInt());
    gl.enable(WebGL.BLEND);
    gl.disable(WebGL.CULL_FACE);
    gl.clearColor(0.0, 1.0, 1.0 , 1.0);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    createProjectionMatrix();
    createViewMatrix();

    withPushedMatrix( () {
      for (var text in textItems) {

        // TODO: Draw the texts
      }
    });

    requestRepaint();
  }
}
