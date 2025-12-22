import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_angle/native-array/index.dart';
import 'package:vector_math/vector_math_64.dart'
    show Vector3, Triangle, Vector2, Aabb3;

import 'vertex_buffer.dart';

/// A data class that stores the geometry for a collection of triangles.
///
/// It holds a flat list of interleaved vertex data (position, texture coordinate,
/// and normal) and provides methods for building and managing this data.
class TriangleMesh {
  // Components are vertex[3], texCoord[2], normal[3]
  static const int componentCount = 8;
  static const int texCoordOffset = 3;
  static const int normalOffset = 5;

  final int triangleCount;

  /// The cached bounding box of the mesh. Null until first computed.
  Aabb3? _bounds;

  late final Float32List verts;

  TriangleMesh(this.triangleCount)
      : verts = Float32List(triangleCount * componentCount * 3);

  TriangleMesh.empty()
      : triangleCount = 0,
        verts = Float32List(0);

  Vector3 getVertex(int index) {
    final int j = index * componentCount;
    return Vector3(verts[j], verts[j + 1], verts[j + 2]);
  }

  Vector3 getNormal(int index) {
    final int j = index * componentCount + normalOffset;
    return Vector3(verts[j], verts[j + 1], verts[j + 2]);
  }

  Triangle getTriangle(int index) {
    final int i = index * componentCount * 3;
    final int j = i + componentCount;
    final int k = j + componentCount;

    return Triangle.points(
        Vector3(verts[i], verts[i + 1], verts[i + 2]),
        Vector3(verts[j], verts[j + 1], verts[j + 2]),
        Vector3(verts[k], verts[k + 1], verts[k + 2]));
  }

  /// Computes the AABB for the entire mesh by iterating directly through the
  /// raw vertex data for efficiency.
  Aabb3 _computeBounds() {
    if (triangleCount == 0) {
      return Aabb3();
    }

    // Initialize min and max with the first vertex's coordinates.
    final minV = Vector3(verts[0], verts[1], verts[2]);
    final maxV = Vector3(verts[0], verts[1], verts[2]);

    // Iterate through the rest of the vertices directly in the flat array.
    for (int i = componentCount; i < verts.length; i += componentCount) {
      final x = verts[i];
      final y = verts[i + 1];
      final z = verts[i + 2];

      minV.x = min(minV.x, x);
      minV.y = min(minV.y, y);
      minV.z = min(minV.z, z);
      maxV.x = max(maxV.x, x);
      maxV.y = max(maxV.y, y);
      maxV.z = max(maxV.z, z);
    }

    return Aabb3.minMax(minV, maxV);
  }

  /// Recomputes the bounding box. Should be called after modifying vertices.
  void recomputeBounds() {
    _bounds = _computeBounds();
  }

  /// Returns the cached bounding box, computing it if necessary.
  Aabb3 getBounds() {
    // Use the null-aware assignment operator to compute only on the first call.
    return _bounds ??= _computeBounds();
  }

  void _addVertex(
      int vertexIndex, Vector3 pos, Vector3 normal, Vector2 tex) {
    int meshIndex = vertexIndex * componentCount;
    verts[meshIndex++] = pos.x;
    verts[meshIndex++] = pos.y;
    verts[meshIndex++] = pos.z;
    verts[meshIndex++] = tex.x;
    verts[meshIndex++] = tex.y;
    verts[meshIndex++] = normal.x;
    verts[meshIndex++] = normal.y;
    verts[meshIndex++] = normal.z;
  }

  /// A low-level method to add a single triangle to the mesh data.
  ///
  /// This is intended to be used by geometry creation APIs like [MeshFactory].
  int addTriangle(Vector3 v0, Vector3 v1, Vector3 v2, Vector3 normal,
      List<Vector2> texCoord, int currentTriangle) {
    int vertexIndex = currentTriangle * 3;
    _addVertex(vertexIndex, v0, normal, texCoord[0]);
    _addVertex(vertexIndex + 1, v1, normal, texCoord[1]);
    _addVertex(vertexIndex + 2, v2, normal, texCoord[2]);
    return currentTriangle + 1;
  }

  void addToVbo(VertexBuffer vbo) {
    int count = triangleCount * 3;
    Float32Array? vertexTextureArray = vbo.requestBuffer(count);
    // Use set() for an efficient block-copy of the data.
    vertexTextureArray?.set(verts);
    vbo.setActiveVertexCount(triangleCount * 3);
  }
}
