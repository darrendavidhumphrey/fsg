import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/gl_context_manager.dart';
import 'package:vector_math/vector_math_64.dart';

import '../glsl_shader.dart';
import 'lighting_shader.dart';
import 'checkerboard_shader.dart';
import 'grid_shader.dart';
import 'one_light_shader.dart';

// --- Source code for basic, unlit shaders ---

String _flatFragmentShader = '''
          #version 300 es
          precision highp float;
          out vec4 FragColor;

          in vec4 vColor;

          void main(void) {
            FragColor = vColor;
          }
        ''';
String _flatVertexShader = '''
          #version 300 es       
          layout(location = 0) in vec3 aVertexPosition;
          layout (location = 3) in vec4 aVertexColor; 

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          out vec4 vColor;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vColor = aVertexColor;
          }
        ''';

String _texturedFragmentShader = '''
#version 300 es
precision highp float;
out vec4 FragColor;

in   vec2 vTextureCoord;

uniform sampler2D uSampler;

void main(void) {
 vec4 texColor = texture(uSampler, vTextureCoord);
 FragColor = texColor;
}''';

String _texturedVertexShader = '''
#version 300 es
layout(location = 0) in vec3 aVertexPosition;
layout (location = 2) in vec2 aTextureCoord;

uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;

out vec2 vTextureCoord;

void main(void) {
gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
vTextureCoord = aTextureCoord;
}
''';

/// A class that manages the lifecycle of all shader programs in the application.
class ShaderList with GlContextManager {
  // --- Shared Attribute Names ---
  static const String v3Attrib = "aVertexPosition";
  static const String c4Attrib = "aVertexColor";
  static const String t2Attrib = "aTextureCoord";
  static const String n3Attrib = "aVertexNormal";

  // --- Shared Uniform Names ---
  static const String uModelView = "uMVMatrix";
  static const String uProj = "uPMatrix";
  static const String uNormal = "uNMatrix";
  static const String uSampler = "uSampler";
  static const String textureSamplerAttrib = 'uSampler';
  // --- Custom Shader Registration ---
  final Map<String, GlslShader> _customShaders = {};

  /// Initializes all shader programs with the given rendering context.
  void init(RenderingContext gl) {
    initializeGl(gl);

    // Register default shaders
    registerShader("oneLight", OneLightShader(gl));
    registerShader("basicLighting", BasicLightingShader(gl));
    registerShader("checkerBoard", CheckerBoardShader(gl));
    registerShader("grid", GridShader(gl));

    // Register generic, unlit shaders from source
    registerShader(
        "v3t2", GlslShader( RenderingContextWrapper(gl), _texturedFragmentShader,_texturedVertexShader,
      [v3Attrib, t2Attrib],
          [uModelView, uProj, textureSamplerAttrib],));
    registerShader(
        "v3c4", GlslShader( RenderingContextWrapper(gl), _flatFragmentShader, _flatVertexShader,
      [v3Attrib, c4Attrib],
      [uModelView, uProj] ));
  }

  /// Registers a custom shader by name for later retrieval.
  void registerShader(String name, GlslShader shader) {
    _customShaders[name] = shader;
  }

  /// Retrieves a previously registered custom shader by name.
  T getShader<T>(String name) {
    final shader = _customShaders[name];
    if (shader == null) {
      throw Exception('Custom shader with name "$name" not found.');
    }
    return shader as T;
  }

  /// Disposes all managed shader programs.
  void dispose() {
    if (!isInitialized) return;

    // Dispose all registered shaders
    for (final shader in _customShaders.values) {
      shader.dispose();
    }
    _customShaders.clear();
  }

  /// A utility to set the standard model-view and projection matrices on a shader.
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
