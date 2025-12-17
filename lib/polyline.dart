import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_angle_jig/util.dart';
import 'package:vector_math/vector_math_64.dart';

class Polyline {
  late Float32List vertices;
  int get length => vertices.length ~/ 3;

  Plane? plane;
  bool planeIsValid = false;
  Vector3? get normal {
    if (planeIsValid) {
      return plane!.normal;
    }
    return null;
  }

  Polyline.fromVector2(List<Vector2> points,{bool computePlane=true}) {
    vertices = Float32List(points.length * 3);
    for (int i = 0, j = 0; i < points.length; i++, j += 3) {
      vertices[j] = points[i].x;
      vertices[j + 1] = points[i].y;
      vertices[j + 2] = 0;
    }
    if (computePlane) {
      setPlane();
    }
  }

  Polyline.fromVector3(List<Vector3> points,{bool computePlane=true}) {
    vertices = Float32List(points.length * 3);
    for (int i = 0, j = 0; i < points.length; i++, j += 3) {
      vertices[j] = points[i].x;
      vertices[j + 1] = points[i].y;
      vertices[j + 2] = points[i].z;
    }
    if (computePlane) {
      setPlane();
    }
  }

  Polyline.fromPolyline(Polyline other) {
    vertices = Float32List(other.vertices.length);
    for (int i = 0; i < other.vertices.length; i++) {
      vertices[i] = other.vertices[i];
    }
    setPlane();
  }

  // Copy from another polyline, but only copy the valid vertices that are
  // provided in the validIndices list.
  Polyline.fromDegenerate(Polyline other,List<int> validIndices) {
    vertices = Float32List(validIndices.length * 3);
    for (int i = 0,j=0; i < validIndices.length; i++,j+=3) {
      int srcIndex = validIndices[i]*3;
      vertices[j] = other.vertices[srcIndex];
      vertices[j+1] = other.vertices[srcIndex+1];
      vertices[j+2] = other.vertices[srcIndex+2];
    }
    setPlane();
  }

  Vector2 getVector2(int index) {
    final int j = index * 3;
    return Vector2(vertices[j], vertices[j + 1]);
  }

  Vector3 getVector3(int index) {
    final int j = index * 3;
    return Vector3(vertices[j], vertices[j + 1], vertices[j + 2]);
  }

  void setPlane() {
    Plane? p = makePlaneFromVertices(
      getVector3(0),
      getVector3(1),
      getVector3(2),
    );
    if (p != null) {
      plane = p;

      planeIsValid = true;
    } else {
      plane = Plane.components(0, 0, 1, 0);
      planeIsValid = false;
    }
  }

  bool containsPoint(Vector3 point) {
    if (!planeIsValid) {
      return false;
    }

    // Check the orientation of the point relative to each edge using the 3D cross product.
    // All cross products (edge x (point - start_of_edge)) should have the same direction relative to the polygon's normal.
    double? referenceDotProductSign;

    for (int i = 0; i < length; i++) {
      final Vector3 p1 = getVector3(i);
      final Vector3 p2 = getVector3((i + 1) % length); // Wrap around

      final Vector3 edge = p2 - p1;
      final Vector3 pointToEdgeStart = point - p1;

      // Compute the cross product in 3D
      final Vector3 crossProductResult = edge.cross(pointToEdgeStart);

      // Check the direction of the cross product relative to the polygon's normal.
      // If the polygon is consistently wound (e.g., counter-clockwise) and the point is inside,
      // all cross products will point "out of the plane" or "into the plane" consistently.
      // The dot product with the polygon's normal determines this orientation.
      final double dotProductWithNormal = crossProductResult.dot(plane!.normal);

      if (dotProductWithNormal.abs() < 1e-6) {
        // The point is collinear with the edge or very close to it.
        // For simplicity, we'll continue. You might want to check if it's on the segment itself.
        continue;
      }

      final double currentSign = dotProductWithNormal.sign;

      if (referenceDotProductSign == null) {
        referenceDotProductSign = currentSign;
      } else if (referenceDotProductSign != currentSign) {
        // The point is on a different side of this edge compared to the previous ones.
        // Therefore, it's outside the convex polygon.
        return false;
      }
    }

    return true; // Point is inside the polygon
  }

  List<int> testForDegenerateVertices() {
    List<int> result = [];
    double minDistance = 0.0001;

    for (int i = 0; i < length; i++) {
      Vector3 p1 = getVector3(i);
      Vector3 p2 = getVector3((i + 1) % length);
      double distance = p1.distanceTo(p2);
      if (distance >= minDistance) {
        result.add(i);
      }
    }
    return result;
  }

  void transform(Vector3 origin3D, Vector3 xAxis, Vector3 yAxis) {
    for (int i = 0, j = 0; i < length; i++, j += 3) {
      Vector3 v = getVector3(i);
      v = origin3D + (xAxis * v.x) + (yAxis * v.y);
      vertices[j] = v.x;
      vertices[j + 1] = v.y;
      vertices[j + 2] = v.z;
    }

    // Update plane equation
    setPlane();
  }

  Vector3? rayIntersect(Ray pickRay) {
    if (!planeIsValid) {
      return null;
    }

    // 1. Ray-Plane Intersection
    // Calculate the 't' value for intersection with the plane of the polygon
    final double denominator = plane!.normal.dot(pickRay.direction);

    // If the ray is parallel to the plane, no intersection unless the ray is in the plane.
    if (denominator.abs() < 1e-6) {
      // Check if the ray is within the plane itself
      final double originToPlaneDistance =
          plane!.normal.dot(pickRay.origin) - plane!.constant;

      if (originToPlaneDistance.abs() < 1e-6) {
        // Ray is in the plane. We need to check if the origin is inside the polygon
        // and if the ray direction points towards the inside. This is more complex
        // and usually handled by other methods (e.g., shooting a 2D ray on the plane).
        // For a simple hit, we'll assume no intersection for parallel rays for now.
        return null;
      }
      return null; // Ray is parallel and not in the plane
    }

    // Calculate t (distance along the ray)
    final double t =
        -(plane!.normal.dot(pickRay.origin) - plane!.constant) / denominator;

    // If t is negative, the intersection point is behind the ray origin.
    if (t < 0) {
      return null;
    }

    final Vector3 intersectionPoint = pickRay.origin + pickRay.direction * t;

    // 2. Point-in-Polygon Test (using the ConvexPolyline's containsPoint method)
    if (containsPoint(intersectionPoint)) {
      return intersectionPoint; // Ray hits the polyline
    } else {
      return null; // Ray hits the plane but misses the polyline
    }
  }

  List<Vector2> getBounds2D() {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i=0; i < length; i++) {
      Vector2 v = getVector2(i);
      minX = min(minX, v.x);
      minY = min(minY, v.y);
      maxX = max(maxX, v.x);
      maxY = max(maxY, v.y);
    }

    return [Vector2(minX, minY), Vector2(maxX, maxY)];
  }
}
