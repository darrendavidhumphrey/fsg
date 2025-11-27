import 'package:flutter/material.dart';
import 'package:flutter_angle/desktop/wrapper.dart';
import 'package:flutter_angle/shared/webgl.dart';
import 'package:flutter_angle_jig/gl_common/bitmap_fonts/bitmap_font_manager.dart';
import 'package:flutter_angle_jig/gl_common/opengl_scene.dart';
import 'package:flutter_angle_jig/gl_common/shaders/built_in_shaders.dart';
import 'package:flutter_angle_jig/gl_common/shaders/gl_materials.dart';
import 'package:flutter_angle_jig/gl_common/shaders/grid_shader.dart';
import 'package:flutter_angle_jig/gl_common/texture_manager.dart';
import 'package:flutter_angle_jig/gl_common/vertex_buffer.dart';

class SimpleExampleCanvas extends OpenGLScene {
  SimpleExampleCanvas() : outerEdgeVbo = VertexBuffer.v3c4(),
        gridVbo = VertexBuffer.v3t2();

  final VertexBuffer outerEdgeVbo;
  final VertexBuffer gridVbo;
  final Size gridExtents = Size(500, 500);

  final Color majorGridColor = Color(0xFFFF0000);
  final Color minorGridColor = Color(0xFF00FF00);
  final Color mmLineColor  = Color(0xFF0000FF);

  void initMaterials() {
    Color defaultGrey = Colors.grey[200]!;
    Color defaultSpecular = Colors.black;
    const double defaultShininess = 5;

    GlMaterialManager().setDefaultMaterial(
      GlMaterial(defaultGrey, defaultGrey, defaultSpecular, defaultShininess),
    );
  }

  @override
  void init(BuildContext context, RenderingContext gl) {
    super.init(context, gl);
    TextureManager().init(gl);

    gridVbo.init(gl);
    outerEdgeVbo.init(gl);

    initMaterials();

    BuiltInShaders().init(gl);
    BitmapFontManager().createDefaultFont();

    gridVbo.makeTexturedUnitQuad(
      Rect.fromLTWH(-gridExtents.width/2, -gridExtents.height/2, gridExtents.width, gridExtents.height),
      0.1,
    );
  }


  @override
  void dispose() {}

  void drawGrid(Matrix4 pMatrix, Matrix4 mvMatrix) {
    GridShader gridShader = BuiltInShaders().grid;
    gl.useProgram(gridShader.program);
    BuiltInShaders.setMatrixUniforms(gridShader, pMatrix, mvMatrix);
    gl.enable(WebGL.DEPTH_TEST);

    gridShader.setResolutionMM(gridExtents.width, gridExtents.height);
    gridShader.setScale(0.1);
    gridShader.setMajorLineSpacingMM(25);
    gridShader.setMinorLineSpacingMM(5);
    gridShader.setMajorLineThickness(0.5);
    gridShader.setMinorLineThickness(0.25);
    gridShader.setMmLineThickness(0.025);
    gridShader.setMajorLineColor(majorGridColor);
    gridShader.setMinorLineColor(minorGridColor);
    gridShader.setMmLineColor( mmLineColor );
    gridVbo.drawSetup();
    gridVbo.drawTriangles();
    gridVbo.drawTeardown();
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
    drawGrid(pMatrix, mvMatrix);

    mvPopMatrix();

    gl.finish();
  }
}
