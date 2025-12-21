import 'package:flutter_angle/flutter_angle.dart';
import 'checkerboard_shader.dart';
import 'package:vector_math/vector_math_64.dart';

import '../glsl_shader.dart';
import 'grid_shader.dart';
import 'lighting_shader.dart';
import 'one_light_shader.dart';

String flatFragmentShader = '''
          #version 300 es
          precision highp float;
          out vec4 FragColor;

          in vec4 vColor;

          void main(void) {
            FragColor = vColor;
          }
        ''';
String flatVertexShader = '''
          #version 300 es
          in vec3 aVertexPosition;
          in vec4 aVertexColor;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          out vec4 vColor;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vColor = aVertexColor;
          }
        ''';

String texturedFragmentShader = '''
#version 300 es
precision highp float;
out vec4 FragColor;

in   vec2 vTextureCoord;

uniform sampler2D uSampler;

void main(void) {
 vec4 texColor = texture(uSampler, vTextureCoord);
 FragColor = texColor;
}''';

String texturedVertexShader = '''
#version 300 es
in vec3 aVertexPosition;
in vec2 aTextureCoord;

uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;

out vec2 vTextureCoord;

void main(void) {
gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
vTextureCoord = aTextureCoord;
}
''';

String testFragmentShader = '''
          #version 300 es
          precision highp float;
          out vec4 FragColor;

          in vec4 vColor;

          void main(void) {
            FragColor = vColor;
          }
        ''';
String testVertexShader = '''
          #version 300 es
          in vec3 aVertexPosition;
          in vec3 aTextureCoord;
          in vec3 aNormal;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          out vec4 vColor;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vColor = vec4(1.0,0.0,0.0,1.0);
          }
        ''';

class ShaderList {
  late GlslShader v3c4;
  late GlslShader v3t2;

  late GlslShader v3t3n4;

  late BasicLightingShader basicLighting;

  late OneLightShader oneLight;

  late GridShader grid;

  late CheckerBoardShader checkerBoard;

  static const String v3Attrib = 'aVertexPosition';
  static const String c4Attrib = 'aVertexColor';
  static const String t2Attrib = 'aTextureCoord';

  static const String n3Attrib = 'aNormal';

  static String uProj = 'uPMatrix';
  static String uModelView = 'uMVMatrix';
  static String textureSamplerAttrib = 'uSampler';

  final Map<String,GlslShader> _shaders = {};

  void init(RenderingContext gl) {

    v3c4 = GlslShader(
      RenderingContextWrapper(gl),
      flatFragmentShader,
      flatVertexShader,
      [v3Attrib, c4Attrib],
      [uModelView, uProj],
    );
    gl.useProgram(v3c4.program);
    _shaders["v3c4"] = v3c4;

    v3t2 = GlslShader(
      RenderingContextWrapper(gl),
      texturedFragmentShader,
      texturedVertexShader,
      [v3Attrib, t2Attrib],
      [uModelView, uProj, textureSamplerAttrib],
    );
    gl.useProgram(v3t2.program);
    _shaders["v3t2"] = v3t2;

    v3t3n4 = GlslShader(
      RenderingContextWrapper(gl),
      testFragmentShader,
      testVertexShader,
      [v3Attrib, t2Attrib, n3Attrib],
      [uModelView, uProj],
    );
    gl.useProgram(v3t3n4.program);
    _shaders["v3t3n4"] = v3t3n4;

    basicLighting = BasicLightingShader(gl);
    gl.useProgram(basicLighting.program);
    _shaders["basicLighting"] = basicLighting;

    grid = GridShader(gl);
    gl.useProgram(grid.program);
    _shaders["grid"] = grid;

    oneLight = OneLightShader(gl);
    gl.useProgram(oneLight.program);
    _shaders["oneLight"] = oneLight;

    checkerBoard = CheckerBoardShader(gl);
    gl.useProgram(checkerBoard.program);
    _shaders["checkerBoard"] = checkerBoard;
  }

  bool addShader(String shaderName,GlslShader shader) {
    if (_shaders.containsKey(shaderName)) {
      return false;
    }

    _shaders[shaderName] = shader;
    return true;
  }

  GlslShader? get(String shaderName) {
    return _shaders[shaderName];
  }

  static void setMatrixUniforms(GlslShader shader,Matrix4 pMatrix, Matrix4 mvMatrix) {
    shader.gl.uniformMatrix4fv(
      shader.uniforms[ShaderList.uProj]!,
      false,
      pMatrix.storage,
    );
    shader.gl.uniformMatrix4fv(
      shader.uniforms[ShaderList.uModelView]!,
      false,
      mvMatrix.storage,
    );
  }
}
