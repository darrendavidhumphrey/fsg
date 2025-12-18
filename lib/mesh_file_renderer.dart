import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/shaders/shaders.dart';
import 'package:fsg/shaders/materials.dart';
import 'package:fsg/shaders/one_light_shader.dart';
import 'package:fsg/vertex_buffer.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'float32_array_filler.dart';
import 'fsg_singleton.dart';
import 'index_buffer.dart';
import 'obj_loader.dart';

// TODO: refactor/rename
class MeshFileRenderer {

  VertexBuffer? vbo;
  IndexBuffer? ibo;
  bool _initialized = false;

  WavefrontObjModel? model;
  MeshFileRenderer();
  late RenderingContext gl;

  bool needsRebuild = true;

  void init(RenderingContext gl) {
    assert(_initialized == false);
    this.gl = gl;

    // TODO: These never get disposed
    vbo = VertexBuffer.v3t2n3();
    ibo = IndexBuffer();
    vbo!.init(gl);
    ibo!.init(gl);
    _initialized = true;
  }

  void setModel(WavefrontObjModel model) {
    this.model = model;
    needsRebuild = true;
  }

  void rebuild() {
    if (model != null && needsRebuild) {
      int numberOfVertices = model!.vertices.length;
      Float32Array? vertexData = vbo!.requestBuffer(numberOfVertices);

      if (vertexData != null) {
        Float32ArrayFiller filler = Float32ArrayFiller(vertexData);

        for (int i = 0; i < model!.vertices.length; i++) {
          P3T2N3 v = model!.vertices[i];
          filler.addV3T2N3(v.position, v.texCoord, v.normal);
        }
      }

      // Download vertex data to vbo
      vbo!.setActiveVertexCount(model!.vertices.length);

      int indexCount = 0;
      for (var mesh in model!.meshes) {
        indexCount += mesh.triangleIndices.length;
      }

      // Convert index list into Int16Array
      Int16Array? indexData = ibo!.requestBuffer(indexCount);

      if (indexData != null) {
        int j = 0;
        for (var mesh in model!.meshes) {
          for (int i = 0; i < mesh.triangleIndices.length; i++, j++) {
            indexData[j] = mesh.triangleIndices[i];
          }
        }
      }

      // Download index data to ibo
      ibo!.setActiveIndexCount(indexCount);
      needsRebuild = false;
    }
  }

  void enableLightingShader(Matrix4 pMatrix, Matrix4 mvMatrix) {
    OneLightShader lightingShader = ShaderList().oneLight;
    gl.useProgram(lightingShader.program);
    ShaderList.setMatrixUniforms(lightingShader, pMatrix, mvMatrix);

    lightingShader.setLightPos(Vector3(40,0,-200));
    lightingShader.setNMatrix(Matrix3.identity());
    lightingShader.setAmbientLight(Colors.grey[900]!);
    lightingShader.setDiffuseLight(Colors.white);
    lightingShader.setSpecularLight(Colors.white);
  }
  void setMaterial(String materialName) {
    GlMaterial material = FSG().materials.getMaterial(materialName);
    OneLightShader shader = ShaderList().oneLight;
    shader.setMaterialAmbient(material.ambient);
    shader.setMaterialDiffuse(material.diffuse);
    shader.setMaterialSpecular(material.specular);
    shader.setShininess(material.shininess);
  }

  void draw(Matrix4 pMatrix, Matrix4 mvMatrix) {
    if (model != null) {
      rebuild();
      gl.enable(WebGL.DEPTH_TEST);
      gl.enable(WebGL.CULL_FACE);
      gl.cullFace(WebGL.BACK);
      vbo!.drawSetup();
      ibo!.drawSetup();

      enableLightingShader(pMatrix, mvMatrix);
      for (var mesh in model!.meshes) {
        const int indexSize = 2;
        String materialName = (mesh.materialName == null) ? "default" : mesh
            .materialName!;

        setMaterial(materialName);

        gl.drawElements(
            WebGL.TRIANGLES, mesh.triangleIndices.length, WebGL.UNSIGNED_SHORT,
            mesh.bufferOffset * indexSize);
      }
      ibo!.drawTeardown();

      vbo!.drawTeardown();
      gl.disable(WebGL.DEPTH_TEST);
      gl.disable(WebGL.CULL_FACE);
    }
  }
}