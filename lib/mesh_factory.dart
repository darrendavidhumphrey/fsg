import 'package:fsg/polyline.dart';
import 'package:fsg/triangle_mesh.dart';
import 'package:fsg/util.dart';
import 'package:vector_math/vector_math_64.dart';

/// A utility class with static methods to create complex [TriangleMesh] objects.
class MeshFactory {
  // Private constructor to prevent instantiation of this utility class.
  MeshFactory._();

  /// Creates a [TriangleMesh] by tessellating a list of [faces].
  static TriangleMesh fromFaces(List<Polyline> faces) {
    // Safely calculate the exact number of triangles needed.
    int triangleCount = 0;
    for (var face in faces) {
      // A convex polygon with N vertices tessellates into N-2 triangles.
      if (face.length > 2) {
        triangleCount += face.length - 2;
      }
    }

    if (triangleCount == 0) {
      return TriangleMesh.empty();
    }

    final mesh = TriangleMesh(triangleCount);

    int currentTriangle = 0;
    for (var face in faces) {
      currentTriangle = _addOutlineAsTriFan(mesh, face, currentTriangle);
    }
    mesh.recomputeBounds();
    return mesh;
  }

  /// Creates a new [TriangleMesh] by extruding a list of [outlines] by a [depth] vector.
  static TriangleMesh extrude(List<Polyline> outlines, Vector3 depth) {
    if (outlines.isEmpty) {
      return TriangleMesh.empty();
    }

    int topCount = 0;
    for (var outline in outlines) {
      if (outline.length > 2) {
        topCount += (outline.length - 2);
      }
    }

    int sideCount = 0;
    for (var outline in outlines) {
      sideCount += (outline.length) * 2;
    }

    int extrudedTriangleCount = topCount * 2 + sideCount;
    if (extrudedTriangleCount == 0) {
      return TriangleMesh.empty();
    }

    TriangleMesh result = TriangleMesh(extrudedTriangleCount);
    int currentTriangle = 0;

    // Add the top faces
    for (var outline in outlines) {
      if (outline.planeIsValid) {
        currentTriangle =
            _addOutlineAsTriFan(result, outline, currentTriangle);
      }
    }

    // Add the bottom faces
    for (var outline in outlines) {
      if (outline.planeIsValid) {
        Vector3 bottomNormal = -outline.normal!;
        currentTriangle = _addOutlineAsReverseTriFan(
            result, outline, bottomNormal, currentTriangle, depth);
      }
    }

    // Add the side faces
    for (var outline in outlines) {
      for (int i = 0; i < outline.length; i++) {
        currentTriangle =
            _makeSideFromEdge(result, outline, i, currentTriangle, depth);
      }
    }

    result.recomputeBounds();

    return result;
  }

  static int _addOutlineAsTriFan(
      TriangleMesh mesh, Polyline outline, int currentTriangle) {
    if (!outline.planeIsValid) return currentTriangle;
    int numTris = outline.length - 2;

    final bounds = outline.getBounds2D();
    double w = bounds.max.x - bounds.min.x;
    double h = bounds.max.y - bounds.min.y;
    double x = bounds.min.x;
    double y = bounds.min.y;

    Vector3 v0 = outline.getVector3(0);
    for (int i = 0; i < numTris; i++) {
      Vector3 v1 = outline.getVector3(i + 2);
      Vector3 v2 = outline.getVector3(i + 1);

      List<Vector2> texCoord = computeTexCoords(v0, v1, v2, x, y, w, h);

      currentTriangle = mesh.addTriangle(
          v0, v1, v2, outline.normal!, texCoord, currentTriangle);
    }
    return currentTriangle;
  }

  static int _addOutlineAsReverseTriFan(TriangleMesh mesh, Polyline outline,
      Vector3 normal, int currentTriangle, Vector3 depth) {
    if (!outline.planeIsValid) return currentTriangle;
    int numTris = outline.length - 2;

    final bounds = outline.getBounds2D();
    double w = bounds.max.x - bounds.min.x;
    double h = bounds.max.y - bounds.min.y;
    double x = bounds.min.x;
    double y = bounds.min.y;

    Vector3 v0 = outline.getVector3(0) + depth;
    for (int i = 0; i < numTris; i++) {
      Vector3 v1 = outline.getVector3(i + 2) + depth;
      Vector3 v2 = outline.getVector3(i + 1) + depth;

      List<Vector2> texCoord = computeTexCoords(v2, v1, v0, x, y, w, h);

      currentTriangle =
          mesh.addTriangle(v2, v1, v0, normal, texCoord, currentTriangle);
    }
    return currentTriangle;
  }

  static int _makeSideFromEdge(TriangleMesh mesh, Polyline outline, int index,
      int currentTriangle, Vector3 depth) {
    Vector3 p1 = outline.getVector3(index % outline.length);
    Vector3 p2 = outline.getVector3((index + 1) % outline.length);
    Vector3 normal = (p2 - p1).cross(depth).normalized();

    Vector3 p1z = p1 + depth;
    Vector3 p2z = p2 + depth;

    // TODO: Calculate correct texture coordinates for sides.
    List<Vector2> texCoord = [Vector2.zero(), Vector2(1, 0), Vector2(1, 1)];
    currentTriangle =
        mesh.addTriangle(p1, p2, p2z, normal, texCoord, currentTriangle);

    texCoord = [Vector2.zero(), Vector2(1, 1), Vector2(0, 1)];
    currentTriangle =
        mesh.addTriangle(p1, p2z, p1z, normal, texCoord, currentTriangle);

    return currentTriangle;
  }
}
