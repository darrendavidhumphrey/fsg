import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_angle/native-array/index.dart';
import 'package:fsg/polyline.dart';
import 'package:fsg/util.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Ray, Triangle, Vector2;

import 'vertex_buffer.dart';

class TriangleMeshHitDetails {
  final TriangleMesh mesh;
  final Vector3 hitPoint;
  final int triangleIndex;

  final double distance;

  late Vector3 normal;
  TriangleMeshHitDetails(this.mesh, this.hitPoint, this.triangleIndex,this.distance) {
    normal = mesh.getNormal(triangleIndex);
  }
}

class TriangleMesh {
  // Components are vertex[3], texCoord[2], normal[3]
  static const int componentCount = 8;
  static const int texCoordOffset = 3;
  static const int normalOffset = 5;

  final int triangleCount;

  bool _boundsValid = false;
  final List<Vector3> _cachedBounds = [];

  late Float32List verts;

  TriangleMesh(this.triangleCount) : verts = Float32List(triangleCount * componentCount*3);

  TriangleMesh.empty() : triangleCount = 0;

  Vector3 getVertex(int index) {
    final int j = index * componentCount;
    return Vector3(verts[j], verts[j+1], verts[j+2]);
  }

  Vector3 getNormal(int index) {
    final int j = index * componentCount + normalOffset;
    return Vector3(verts[j], verts[j+1], verts[j+2]);
  }

  Triangle getTriangle(int index) {
    final int i = index * componentCount*3;
    final int j = i + componentCount;
    final int k = j + componentCount;

    return Triangle.points(
        Vector3(verts[i], verts[i+1], verts[i+2]),
        Vector3(verts[j], verts[j+1], verts[j+2]),
        Vector3(verts[k], verts[k+1], verts[k+2]));
  }

  Vector3? rayTriangleIntersect(int triangleIndex,Vector3 rayOrigin, Vector3 rayDirection,
      {double epsilon = 0.000001}) {
    if (!_boundsValid) {
      return null;
    }

    final Vector3 point0 = getVertex(triangleIndex);
    final edge1 = getVertex(triangleIndex+1) - point0;
    final edge2 = getVertex(triangleIndex+2) - point0;

    final h = rayDirection.cross(edge2);
    final a = edge1.dot(h);

    if (a > -epsilon && a < epsilon) {
      return null; // Ray is parallel to the triangle.
    }

    final f = 1.0 / a;
    final s = rayOrigin - point0;
    final u = f * s.dot(h);

    if (u < 0.0 || u > 1.0) {
      return null; // Intersection point outside the triangle.
    }

    final q = s.cross(edge1);
    final v = f * rayDirection.dot(q);


    if (v < 0.0 || u + v > 1.0) {
      return null; // Intersection point outside the triangle.
    }

    final t = f * edge2.dot(q);


    if (t > epsilon) {
      // Ray intersects the triangle
      return rayOrigin + rayDirection * t;
    } else {
      // A negative t means the intersection is behind the ray origin.
      return null;
    }
  }

  TriangleMeshHitDetails? rayIntersect(Ray ray,
      {double epsilon = 0.000001}) {

    for (int i=0; i < triangleCount; i++) {

      Vector3? hit = rayTriangleIntersect(i,ray.origin, ray.direction);
      if (hit != null) {
        return TriangleMeshHitDetails(this, hit, i,ray.origin.distanceTo(hit));
      }
    }
    return null;
  }

  List<Vector3> computeBounds() {
    if (triangleCount == 0) {
      return [Vector3.zero(), Vector3.zero()];
    }
    Vector3 minV = getVertex(0);
    Vector3 maxV = getVertex(0);


    for (int i=0,j=0; i < triangleCount; i++,j+= componentCount) {
      minV.x = min(minV.x,verts[j]);
      minV.y = min(minV.y,verts[j+1]);
      minV.z = min(minV.z,verts[j+2]);

      maxV.x = max(maxV.x,verts[j]);
      maxV.y = max(maxV.y,verts[j+1]);
      maxV.z = max(maxV.z,verts[j+2]);
    }

    return [minV,maxV];
  }

  static String vecToString(Vector3 vec) {
    return "${vec.x.toStringAsFixed(6)} ${vec.y.toStringAsFixed(6)} ${vec.z.toStringAsFixed(6)}";
  }

  static String triangleToString(Vector3 v0, Vector3 v1, Vector3 v2) {
    String result = "";
    result += "${vecToString(v0)} ";
    result += "${vecToString(v1)} ";
    result += "${vecToString(v2)}\n";
    return result;
  }

  String meshToString(String instanceName) {
    String result = "";
    result += "TriangleMesh: $instanceName $triangleCount\n";
    for (int i=0,j=0; i < triangleCount; i++,j+=3) {
      Vector3 v0 = getVertex(j);
      Vector3 v1 = getVertex(j+1);
      Vector3 v2 = getVertex(j+2);
      result += triangleToString(v0,v1,v2);
    }
    result += "End TriangleMesh\n";
    return result;
  }

  void recomputeBounds() {
    _cachedBounds.clear();
    _cachedBounds.addAll(computeBounds());
    _boundsValid = true;
  }

  List<Vector3> getBounds() {
    if (!_boundsValid) {
      recomputeBounds();
    }
    return _cachedBounds;
  }

  int addOutlineAsTriFan(Polyline outline,int currentTriangle) {
    int numTris = outline.length-2;

    final bounds = outline.getBounds2D();
    double w = bounds.max.x - bounds.min.x;
    double h = bounds.max.y - bounds.min.y;
    double x = bounds.min.x;
    double y = bounds.min.y;

    Vector3 v0 = outline.getVector3(0);
    for (int i=0; i < numTris; i++) {
      Vector3 v1 = outline.getVector3(i+2);
      Vector3 v2 = outline.getVector3(i+1);

      List<Vector2> texCoord = computeTexCoords(
        v0, v1, v2,
        x,
        y,
        w,
        h,
      );


      currentTriangle = addTriangle(v0, v1, v2, outline.normal!, texCoord,currentTriangle);
    }
    return currentTriangle;
  }


  int addOutlineAsReverseTriFan(Polyline outline,Vector3 normal,int currentTriangle,Vector3 depth) {
    int numTris = outline.length-2;

    final bounds = outline.getBounds2D();
    double w = bounds.max.x - bounds.min.x;
    double h = bounds.max.y - bounds.min.y;
    double x = bounds.min.x;
    double y = bounds.min.y;

    Vector3 v0 = outline.getVector3(0);
    v0 += depth;
    for (int i=0; i < numTris; i++) {
      Vector3 v1 = outline.getVector3(i+2);
      Vector3 v2 = outline.getVector3(i+1);
      v1 += depth;
      v2 += depth;

      List<Vector2> texCoord = computeTexCoords(
        v2, v1, v0,
        x,
        y,
        w,
        h,
      );

      currentTriangle = addTriangle(v2, v1, v0, normal, texCoord,currentTriangle);
    }
    return currentTriangle;
  }

  int addTriangle(Vector3 v0, Vector3 v1, Vector3 v2, Vector3 normal,List<Vector2> texCoord,int currentTriangle) {
    int meshIndex = currentTriangle * componentCount*3;

    // Vertex 0
    verts[meshIndex++] = v0.x;
    verts[meshIndex++] = v0.y;
    verts[meshIndex++] = v0.z;

    // Texture coordinates
    verts[meshIndex++] = texCoord[0].x;
    verts[meshIndex++] = texCoord[0].y;

    // Copy the normal
    verts[meshIndex++] = normal.x;
    verts[meshIndex++] = normal.y;
    verts[meshIndex++] = normal.z;

    // Vertex 1
    verts[meshIndex++] = v1.x;
    verts[meshIndex++] = v1.y;
    verts[meshIndex++] = v1.z;

    // Texture coordinates
    verts[meshIndex++] = texCoord[1].x;
    verts[meshIndex++] = texCoord[1].y;

    // Copy the normal
    verts[meshIndex++] = normal.x;
    verts[meshIndex++] = normal.y;
    verts[meshIndex++] = normal.z;

    // Vertex 2
    verts[meshIndex++] = v2.x;
    verts[meshIndex++] = v2.y;
    verts[meshIndex++] = v2.z;

    // Texture coordinates
    verts[meshIndex++] = texCoord[2].x;
    verts[meshIndex++] = texCoord[2].y;

    // Copy the normal
    verts[meshIndex++] = normal.x;
    verts[meshIndex++] = normal.y;
    verts[meshIndex++] = normal.z;

    // Added 1 triangle
    return currentTriangle+1;
  }

  int makeSideFromEdge(Polyline outline,int index,int currentTriangle,Vector3 depth) {
    Vector3 p1 = outline.getVector3(index % outline.length);
    Vector3 p2 = outline.getVector3((index+1) % outline.length);
    Vector3 normal = p1.cross(p2);

    Vector3 p1z = p1+depth;
    Vector3 p2z = p2+depth;

    List<Vector2> texCoord = [Vector2(0,0),Vector2(1,0),Vector2(1,1)];
    currentTriangle = addTriangle(p1, p2, p2z,normal,texCoord,currentTriangle);

    texCoord = [Vector2(0,0),Vector2(1,1),Vector2(0,1)];
    currentTriangle = addTriangle(p1, p2z, p1z,normal,texCoord,currentTriangle);

    return currentTriangle;
  }

  void addToVbo(VertexBuffer vbo) {
    int count = triangleCount*3;
    Float32Array? vertexTextureArray = vbo.requestBuffer(count);
    vertexTextureArray!.toDartList().setAll(0, verts);
    vbo.setActiveVertexCount(triangleCount*3);
  }

  static TriangleMesh extrude(List<Polyline> outlines,Vector3 depth) {
    if (outlines.isEmpty) {
      return TriangleMesh.empty();
    }

    int topCount = 0;
    for (var outline in outlines) {
      // A polyline with N points tessellates to N-1 triangles
      topCount += (outline.length-2);
    }

    int sideCount=0;
    for (var outline in outlines) {
      // A polyline with N points has N sides, each which makes 2 triangles
      sideCount += (outline.length)*2;
    }

    // Total triangle count is sum of top, sides and bottom
    int extrudedTriangleCount = topCount*2 + sideCount;
    if (extrudedTriangleCount == 0) {
      return TriangleMesh.empty();
    }

    TriangleMesh result = TriangleMesh(extrudedTriangleCount);
    int currentTriangle = 0;

    for (var outline in outlines) {
      if (outline.planeIsValid) {
        currentTriangle = result.addOutlineAsTriFan(outline, currentTriangle);
      }
    }

    // Add the sides faces
    for (var outline in outlines) {
      for (int i=0; i < outline.length; i++) {
        currentTriangle = result.makeSideFromEdge(outline, i,currentTriangle,depth);
      }
    }

    Vector3 bottomNormal = result.getVertex(0).cross(result.getVertex(1));
    bottomNormal.normalize();

    // Add the bottoms as reversed versions of the top
    for (var outline in outlines) {
      if (outline.planeIsValid) {
        currentTriangle = result.addOutlineAsReverseTriFan(outline, bottomNormal, currentTriangle,depth);
      }
    }

    // Compute bounding box
    result.recomputeBounds();

    return result;
  }
}
