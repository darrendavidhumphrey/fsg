import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/shaders/shaders.dart';
import 'package:fsg/shaders/materials.dart';
import 'package:fsg/shaders/one_light_shader.dart';
import 'package:fsg/vertex_buffer.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'fsg_singleton.dart';
import 'index_buffer.dart';
import 'obj_loader.dart';

class MeshFileRenderer {
  final VertexBuffer vbo;
  final IndexBuffer ibo;
  final WavefrontObjModel model;
  final RenderingContext gl;


  /// Creates a renderer for a specific model and initializes its GL resources.
  MeshFileRenderer(this.gl, this.model)
      : ibo = IndexBuffer(gl),
        vbo = model.vertexBuffer {
    buildIndexBuffer();
  }

  /// Rebuilds the Index Buffer for the model.
  /// The Vertex Buffer is already handled by the WavefrontObjModel.
  void buildIndexBuffer() {
      // The model's vertex buffer is already built and populated.
      // We only need to build the index buffer.

      int indexCount = 0;
      for (var mesh in model.meshes) {
        indexCount += mesh.triangleIndices.length;
      }

      // Convert index list into Int16Array
      Int16Array? indexData = ibo.requestBuffer(indexCount);

      if (indexData != null) {
        int j = 0;
        for (var mesh in model.meshes) {
          for (int i = 0; i < mesh.triangleIndices.length; i++, j++) {
            indexData[j] = mesh.triangleIndices[i];
          }
        }
      }

      // Download index data to ibo
      ibo.setActiveIndexCount(indexCount);
  }

  void enableLightingShader(Matrix4 pMatrix, Matrix4 mvMatrix) {
    var lightingShader = FSG().shaders.oneLight;
    gl.useProgram(lightingShader.program);
    ShaderList.setMatrixUniforms(lightingShader, pMatrix, mvMatrix);

    lightingShader.setLightPos(Vector3(40, 0, -200));
    lightingShader.setNMatrix(Matrix3.identity());
    lightingShader.setAmbientLight(Colors.grey[900]!);
    lightingShader.setDiffuseLight(Colors.white);
    lightingShader.setSpecularLight(Colors.white);
  }

  void setMaterial(String materialName) {
    GlMaterial material = FSG().materials.getMaterial(materialName);
    OneLightShader shader = FSG().shaders.oneLight;
    shader.setMaterialAmbient(material.ambient);
    shader.setMaterialDiffuse(material.diffuse);
    shader.setMaterialSpecular(material.specular);
    shader.setShininess(material.shininess);
  }

  void draw(Matrix4 pMatrix, Matrix4 mvMatrix) {
    gl.enable(WebGL.DEPTH_TEST);
    gl.enable(WebGL.CULL_FACE);
    gl.cullFace(WebGL.BACK);

    vbo.bind();
    ibo.bind();

    enableLightingShader(pMatrix, mvMatrix);
    for (var mesh in model.meshes) {
      const int indexSize = 2; // Size of UNSIGNED_SHORT
      String materialName =
          (mesh.materialName == null) ? "default" : mesh.materialName!;

      setMaterial(materialName);

      gl.drawElements(WebGL.TRIANGLES, mesh.triangleIndices.length,
          WebGL.UNSIGNED_SHORT, mesh.bufferOffset * indexSize);
    }
    ibo.unbind();

    vbo.unbind();
    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.CULL_FACE);
  }
}
