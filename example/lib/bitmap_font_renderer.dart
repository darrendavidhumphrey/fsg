import 'dart:ui';

import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:fsg/fsg.dart';

class BitmapFontRenderer extends SceneLayer {
  BitmapFontRenderer();
  final List<BitmapText> _children = [];

  void addTextItems(List<BitmapText> text) {
    for (var child in _children) {
      child.dispose();
    }
    _children.clear();
    _children.addAll(text);
    setNeedsRebuild(true);
  }

  @override
  void rebuild(DateTime now) {
    // Rebuild children if needed
    for (BitmapText child in _children) {
      if (child.needsRebuild) {
        child.rebuild(gl,now);
      }
    }
  }

  void drawSetup(Matrix4 pMatrix, Matrix4 mvMatrix) {
    var shader = FSG().shaders.getShader<BitmapTextShader>();
    gl.useProgram(shader.program);
    ShaderList.setMatrixUniforms(shader, pMatrix, mvMatrix);

    gl.enable(WebGL.BLEND);
    gl.activeTexture(WebGL.TEXTURE0);
    gl.blendFuncSeparate(
      WebGL.SRC_ALPHA,
      WebGL.ONE_MINUS_SRC_ALPHA,
      WebGL.ONE,
      WebGL.ONE_MINUS_SRC_ALPHA,
    );
    gl.uniform1i(shader.uniforms[ShaderList.textureSamplerAttrib]!, 0);
  }

  @override
  void draw(Matrix4 pMatrix, Matrix4 mvMatrix) {
    if (_children.isNotEmpty) {
      drawSetup(pMatrix, mvMatrix);

      // Iterate through children and draw them
      WebGLTexture? currentTexture;

      for (var child in _children) {

        if (child.font!.isInitialized) {
          // Don't  change texture unless needed
          if (currentTexture != child.font!.fontTexture) {
            currentTexture = child.font!.fontTexture;
            gl.bindTexture(WebGL.TEXTURE_2D, currentTexture);
          }
          // TODO: Is this needed to do per child?
          child.vbo!.bind();
          child.vbo!.drawTriangles();
          child.vbo!.unbind();
        }
      }

    }
  }
}
