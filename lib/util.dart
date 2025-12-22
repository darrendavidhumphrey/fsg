import 'dart:math';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

extension Dist2D on Vector3 {
  double distanceToLineSegment3D(Vector3 a, Vector3 b) {
    // Vector representing the line segment
    Vector3 segmentVector = b - a;

    // Vector from the segment's start point to the given point
    Vector3 pointToSegmentStart = this - a;

    // Calculate the projection of 'pointToSegmentStart' onto 'segmentVector'
    // using the dot product to determine 't'
    // t is the parameter along the line: 0 <= t <= 1 means the closest point is on the segment
    double t = pointToSegmentStart.dot(segmentVector) / segmentVector.length2;

    // Clamp 't' to be within the segment's bounds (0 to 1)
    t = t.clamp(0.0, 1.0);

    // Calculate the closest point on the line segment
    Vector3 closestPointOnSegment = a + segmentVector * t;

    // Return the distance between the given point and the closest point on the segment
    return distanceTo(closestPointOnSegment);
  }
}

extension QuadNormal on Quad {
  Vector3 getSurfaceNormal() {
    Vector3 normal = (point1 - point0).cross(point2 - point0);
    normal.normalize();

    return normal;
  }
}

extension VectorToString on Vector3 {
  String niceString() {
    return "(x: ${x.toStringAsFixed(2)} y: ${y.toStringAsFixed(2)} z: ${z.toStringAsFixed(2)})";
  }
}

extension QuadToString on Quad {
  String niceString() {
    String pointsStr = "Quad =";

    pointsStr += "${point0.niceString()} ";
    pointsStr += "${point1.niceString()} ";
    pointsStr += "${point2.niceString()} ";
    pointsStr += point3.niceString();

    return pointsStr;
  }
}

Plane? makePlaneFromVertices(Vector3 p1, Vector3 p2, Vector3 p3) {
  // 1. Calculate two vectors lying on the plane
  Vector3 v1 = p2 - p1;
  Vector3 v2 = p3 - p1;

  // 2. Calculate the cross product to get the normal vector
  // The cross product of two vectors in a plane gives a vector perpendicular to that plane.
  Vector3 normal = v1.cross(v2);

  // Ensure the normal vector is not a zero vector, which would mean the points are collinear
  if (normal.length2 == 0) {
    return null;
  }

  // You can optionally normalize the normal vector if you want a unit normal
  normal.normalize();

  // 3. Calculate the 'd' value (Ax + By + Cz = D)
  //  Take any of the three points (e.g., p1) and use the dot product with the normal vector
  double d = -normal.dot(p1);

  return Plane.normalconstant(normal, d);
}

bool quadsAreEqual(Quad q1, Quad q2) {
  return (q1.point0 == q2.point0 &&
      q1.point1 == q2.point1 &&
      q1.point2 == q2.point2 &&
      q1.point3 == q2.point3);
}

extension QuaternionExtensions on Quaternion {
  double dotProduct(Quaternion q2) {
    return x * q2.x + y * q2.y + z * q2.z + w * q2.w;
  }

  void negate() {
    x = -x;
    y = -y;
    z = -z;
    w = -w;
  }

  Quaternion negated() {
    return Quaternion(-x, -y, -z, -w);
  }
}

Quaternion slerp(Quaternion q1, Quaternion q2, double t) {
  // Ensure unit quaternions
  q1.normalize();
  q2.normalize();

  double dot = q1.dotProduct(q2);

  // If the dot product is negative, the quaternions are in opposite hemispheres,
  // so negate one of them to take the shorter path.
  if (dot < 0.0) {
    q2.negate();
    dot = -dot;
  }

  // Handle near-parallel case to prevent division by zero or large errors
  const double dotThreshold = 0.9995;
  if (dot > dotThreshold) {
    // If the quaternions are very close, use linear interpolation (LERP)
    // and re-normalize to maintain unit length.
    Quaternion result = Quaternion.identity();
    result.x = q1.x + t * (q2.x - q1.x);
    result.y = q1.y + t * (q2.y - q1.y);
    result.z = q1.z + t * (q2.z - q1.z);
    result.w = q1.w + t * (q2.w - q1.w);
    result.normalize();
    return result;
  }

  // Calculate the angle between the quaternions
  double theta = acos(dot);

  // Calculate the interpolation weights
  double sinTheta = sin(theta);
  double invSinTheta = 1.0 / sinTheta;
  double weight1 = sin((1.0 - t) * theta) * invSinTheta;
  double weight2 = sin(t * theta) * invSinTheta;

  // Perform the spherical linear interpolation
  Quaternion result = Quaternion.identity();
  result.x = q1.x * weight1 + q2.x * weight2;
  result.y = q1.y * weight1 + q2.y * weight2;
  result.z = q1.z * weight1 + q2.z * weight2;
  result.w = q1.w * weight1 + q2.w * weight2;
  return result;
}

extension TriangleHit on Triangle {
  Vector3? rayTriangleIntersect(Vector3 rayOrigin, Vector3 rayDirection,
      {double epsilon = 0.000001}) {
    final edge1 = point1 - point0;
    final edge2 = point2 - point0;
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
}

// Finds the intersection point of a line segment and a vertical line
Vector3? getIntersectionWithVerticalLine(
    Vector3 p1,
    Vector3 p2,
    double verticalLineX,
    ) {
  // Calculate the parameter t for the intersection point.
  // The intersection occurs when the x-coordinate of the line segment equals verticalLineX.
  // x1 + t * (x2 - x1) = verticalLineX
  // t * (x2 - x1) = verticalLineX - x1
  // t = (verticalLineX - x1) / (x2 - x1)
  double t = (verticalLineX - p1.x) / (p2.x - p1.x);

  // Check if the intersection point lies on the line segment
  // The intersection lies on the segment if 0 <= t <= 1.
  if (t >= -1e-6 && t <= 1 + 1e-6) {
    // Use a small tolerance for floating point comparisons
    // Calculate the y-coordinate of the intersection point using the parametric equation.
    // y = y1 + t * (y2 - y1)
    double intersectionY = p1.y + t * (p2.y - p1.y);

    // Return the intersection point.
    return Vector3(verticalLineX, intersectionY, 0);
  }

  // The intersection point does not lie on the line segment.
  return null;
}

// Function to calculate the intersection point of a line segment with a horizontal line
Vector3? getIntersectionWithHorizontalLine(
    Vector3 p1,
    Vector3 p2,
    double horizontalLineY,
    ) {
  // Calculate the parameter t for the intersection point.
  // The intersection occurs when the y-coordinate of the line segment equals horizontalLineY.
  // y1 + t * (y2 - y1) = horizontalLineY
  // t * (y2 - y1) = horizontalLineY - y1
  // t = (horizontalLineY - y1) / (y2 - y1)
  double t = (horizontalLineY - p1.y) / (p2.y - p1.y);

  // Check if the intersection point lies on the line segment
  // The intersection lies on the segment if 0 <= t <= 1.
  if (t >= -1e-6 && t <= 1 + 1e-6) {
    // Use a small tolerance for floating point comparisons
    // Calculate the x-coordinate of the intersection point using the parametric equation.
    // x = x1 + t * (x2 - x1)
    double intersectionX = p1.x + t * (p2.x - p1.x);

    // Return the intersection point.
    return Vector3(intersectionX, horizontalLineY, 0);
  }

  // The intersection point does not lie on the line segment.
  return null;
}

List<Vector2> computeTexCoords(
    Vector3 p0,
    Vector3 p1,
    Vector3 p2,
    double x,
    double y,
    double w,
    double h,
    ) {
  if (x == 0) {
    x = 0.5;
  }
  if (y == 0) {
    y = 0.5;
  }
  return [
    Vector2((p0.x - x) / w, (p0.y - y) / h),
    Vector2((p1.x - x) / w, (p1.y - y) / h),
    Vector2((p2.x - x) / w, (p2.y - y) / h),
  ];
}

Vector3 unProject(Vector4 ndcVector,Matrix4 inverseCombinedMatrix) {
  final Vector4 homogeneousCoords = inverseCombinedMatrix.transform(
    ndcVector,
  );

  // Un-project the point
  if ( homogeneousCoords.w.abs() < 1e-9) {
    // Avoid division by very small value, indicates an invalid unprojection
    return Vector3.zero();
  }

  final double invW = 1.0 / homogeneousCoords.w;
  return Vector3(
    homogeneousCoords.x * invW,
    homogeneousCoords.y * invW,
    homogeneousCoords.z * invW,
  );
}

Ray computePickRay(Offset mousePosition,Size viewportSize,Matrix4 projection,Matrix4 view) {
  double winX = mousePosition.dx;
  double winY = mousePosition.dy;

  final Matrix4 combinedMatrix = projection * view;
  final Matrix4 inverseCombinedMatrix = Matrix4.copy(combinedMatrix);
  inverseCombinedMatrix.invert();

  final double ndcX = (winX * 2.0) / viewportSize.width - 1.0;
  final double ndcY = (winY * 2.0) / viewportSize.height - 1.0;

  // Create a homogeneous vector in NDC space at the near clipping plane
  final Vector4 ndcVectorNear = Vector4(ndcX, ndcY, -1, 1.0);

  // Create a homogeneous vector in NDC space at the far clipping plane
  final Vector4 ndcVectorFar = Vector4(ndcX, ndcY, 1, 1.0);

  final Vector3 nearResult = unProject(ndcVectorNear,inverseCombinedMatrix);
  final Vector3 farResult = unProject(ndcVectorFar,inverseCombinedMatrix);

  // DDH: Changed to calculate direction vector instead of passing farResult
  Vector3 direction = farResult - nearResult;
  return Ray.originDirection(nearResult, direction);
}

Vector3? intersectRayWithPlane(Ray ray,Plane plane) {
  double denominator = plane.normal.dot(ray.direction);

  if (denominator.abs()  < 0.0001) {
    return null;
  }

  double t = -(plane.normal.dot(ray.origin) - plane.constant) / denominator;

  if (t >= 0.0 && t <= 1.0) {
    // Intersection point lies within the segment
    Vector3 intersectionPoint = ray.origin + (ray.direction * t);
    return intersectionPoint;
  }

  return null;
}

Vector3? intersectRayPlaneFromPointAndNormal(
    Ray ray,
    Vector3 planeOrigin, // A point on the plane (e.g., where the click started)
    Vector3 planeNormal) { // The transformed plane normal
  final direction = ray.direction;
  final double denom = direction.dot(planeNormal);

  // If the ray is parallel to the plane or pointing away
  if (denom == 0.0 || (denom < 0 && planeNormal.dot(ray.origin - planeOrigin) > 0)) {
    return null; // No intersection or ray is parallel
  }

  final double t = (planeOrigin - ray.origin).dot(planeNormal) / denom;

  if (t >= 0) { // Intersection point is in front of the ray origin
    return ray.origin + direction * t;
  }

  return null; // Intersection point is behind the ray origin
}

({Vector3 right, Vector3 up, Vector3 forward}) getCameraAxes(Matrix4 viewMatrix) {
  // The view matrix transforms world coordinates to view coordinates.
  // The inverse of the view matrix transforms view coordinates to world coordinates (camera's local axes).
  final Matrix4 inverseViewMatrix = viewMatrix.clone();
  inverseViewMatrix.invert();

  // Extract the camera's right, up, and forward vectors (normalized) from the inverse view matrix
  final Vector3 right = Vector3(inverseViewMatrix.entry(0, 0), inverseViewMatrix.entry(1, 0), inverseViewMatrix.entry(2, 0)).normalized();
  final Vector3 up = Vector3(inverseViewMatrix.entry(0, 1), inverseViewMatrix.entry(1, 1), inverseViewMatrix.entry(2, 1)).normalized();
  final Vector3 forward = Vector3(inverseViewMatrix.entry(0, 2), inverseViewMatrix.entry(1, 2), inverseViewMatrix.entry(2, 2)).normalized();

  return (right: right, up: up, forward: forward);
}