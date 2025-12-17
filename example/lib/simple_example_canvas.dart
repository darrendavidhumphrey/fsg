import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:flutter_angle_jig/fsg.dart';

class SimpleExampleCanvas extends Scene {
  SimpleExampleCanvas() :
        exampleVbo = VertexBuffer.v3t2();

  final VertexBuffer exampleVbo;
  final Size quadExtents = Size(500, 500);

  final Color color1 = Color(0xFFFF0000);
  final Color color2 = Color(0xFF00FF00);

  @override
  void init(BuildContext context, RenderingContext gl) {
    super.init(context, gl);
    exampleVbo.init(gl);

    exampleVbo.makeTexturedUnitQuad(
      Rect.fromLTWH(-quadExtents.width/2, -quadExtents.height/2, quadExtents.width, quadExtents.height),
      0.1,
    );
  }

  @override
  void dispose() {}

  void drawVBO(Matrix4 pMatrix, Matrix4 mvMatrix) {
    var shader = FSG().shaders.checkerBoard;
    gl.useProgram(shader.program);
    ShaderList.setMatrixUniforms(shader, pMatrix, mvMatrix);
    gl.enable(WebGL.DEPTH_TEST);

    shader.setPatternColor1(color1);
    shader.setPatternColor2(color2);
    shader.setPatternScale(4);

    exampleVbo.drawSetup();
    exampleVbo.drawTriangles();
    exampleVbo.drawTeardown();
  }

  @override
  void drawScene() {
    gl.clearColor(1.0, 1.0, 1.0, 1.0);

    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    gl.enable(WebGL.DEPTH_TEST);
    gl.enable(WebGL.BLEND);
    gl.disable(WebGL.CULL_FACE);
    gl.depthFunc(WebGL.LESS);

    mvPushMatrix();
    // Matrices are set from orbit view
    drawVBO(pMatrix, mvMatrix);

    mvPopMatrix();

    gl.finish();
  }
}
