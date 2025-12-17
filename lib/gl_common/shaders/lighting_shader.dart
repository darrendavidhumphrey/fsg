import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';

import '../gl_program.dart';
import 'shaders.dart';

const String _lightingVertexShader = """
#version 300 es
precision highp float; // You can adjust this based on your needs

in vec3 aVertexPosition;
in vec2 aTextureCoord;
in vec3 aNormal; 

out vec2 vTextureCoord;
out vec3 LightIntensity;
 
uniform vec3 Kd;  
uniform vec3 Ld;  
uniform vec4 lightPos; 
uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;


void main() { 
   vec3 tnorm = aNormal; 
	 vec4 eyeCoords = uMVMatrix * vec4(aVertexPosition,1.0); 
	 vec3 s = normalize(vec3(lightPos - eyeCoords)); 
   vec3 ambient = vec3(0,0.0,0);
	 LightIntensity = Ld * Kd * max( dot( s, tnorm ), 0.0 ) + ambient; 
	 gl_Position =  uPMatrix * uMVMatrix * vec4(aVertexPosition,1.0); 
}
""";

const String _lightingFragmentShader = """
#version 300 es
precision highp float;
in vec2 vTextureCoord;
in vec3 LightIntensity; 
out vec4 FragColor;

uniform sampler2D uSampler;
 
void main() {
	FragColor = vec4(LightIntensity, 1.0); 
}
""";

class BasicLightingShader extends GlslShader {
  static String uLightPos = "lightPos";
  static String uKd = "Kd";
  static String uLd = "Ld";

  BasicLightingShader(RenderingContext gl)
    : super(
        gl,
        _lightingFragmentShader,
        _lightingVertexShader,
        [
          ShaderList.v3Attrib,
          ShaderList.t2Attrib,
          ShaderList.n3Attrib,
        ],
        [uKd, uLd, uLightPos, ShaderList.uModelView, ShaderList.uProj],
      );

  void setLightPos(Vector3 v) {
    gl.uniform4f(uniforms[uLightPos]!, v.x, v.y, v.z, 1.0);
  }

  void setKd(Vector3 v) {
    gl.uniform3f(uniforms[uKd]!, v.x, v.y, v.z);
  }

  void setLd(Vector3 v) {
    gl.uniform3f(uniforms[uLd]!, v.x, v.y, v.z);
  }
}
