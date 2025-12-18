import 'dart:ui';
import 'package:flutter_angle/flutter_angle.dart';
import 'logging.dart';

/// Create a WebGL [Program], compiling [Shader]s from passed in sources and
/// cache [UniformLocation]s and AttribLocations.
class GlslShader with LoggableClass {
  Map<String, int> attributes = <String, int>{};
  Map<String, UniformLocation> uniforms = <String, UniformLocation>{};
  late Program program;

  late dynamic fragShader, vertShader;

  RenderingContext gl;
  GlslShader(
      this.gl,
      String fragSrc,
      String vertSrc,
      List<String> attributeNames,
      List<String> uniformNames
      ) {
    fragShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fragShader, fragSrc);
    gl.compileShader(fragShader);

    vertShader = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vertShader, vertSrc);
    gl.compileShader(vertShader);

    program = gl.createProgram();
    gl.attachShader(program, vertShader);
    gl.attachShader(program, fragShader);
    gl.linkProgram(program);

    for (String attrib in attributeNames) {
      int attributeLocation = gl.getAttribLocation(program, attrib).id;
      gl.enableVertexAttribArray(attributeLocation);
      gl.checkError(attrib);
      attributes[attrib] = attributeLocation;
    }
    for (String uniform in uniformNames) {
      var uniformLocation = gl.getUniformLocation(program, uniform);
      gl.checkError(uniform);
      logPedantic("Uniform: $uniform, Location: ${uniformLocation.id}");
      uniforms[uniform] = UniformLocation(uniformLocation.id);
    }
  }
}