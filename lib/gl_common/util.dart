import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

Matrix4 createLookAtMatrix(Vector3 eye, Vector3 center, Vector3 up) {
  // 1. Calculate the forward vector (Z-axis)
  // This vector points from the camera's position (eye) towards the target (center).
  // Remember to normalize the result of the vector subtraction, since we want a unit vector.
  Vector3 zAxis = (eye - center)..normalize();

  // 2. Calculate the right vector (X-axis)
  // This vector is perpendicular to both the forward vector and the up vector.
  // It represents the camera's horizontal axis.
  Vector3 xAxis = up.cross(zAxis)..normalize();

  // 3. Calculate the true up vector (Y-axis)
  // This vector ensures the camera's up direction is truly orthogonal to the other two axes.
  Vector3 yAxis = zAxis.cross(xAxis)..normalize();

  // Create a new Matrix4 and set its values based on the calculated vectors.
  // The view matrix transforms world coordinates into camera's view space.
  // The first three columns typically represent the camera's local x, y, and z axes (right, up, and forward respectively),
  // and the fourth column represents the camera's position.
  // Note: The view matrix is the inverse of the camera's world transform,
  // so the translation component is actually the negative dot product of the camera position with each of the basis vectors.


  Matrix4 lookAtMatrix = Matrix4(
    xAxis.x,
    yAxis.x,
    zAxis.x,
    0.0, // Column 0 (Right vector)
    xAxis.y,
    yAxis.y,
    zAxis.y,
    0.0, // Column 1 (Up vector)
    xAxis.z,
    yAxis.z,
    zAxis.z,
    0.0, // Column 2 (Forward vector)
    -xAxis.dot(eye),
    -yAxis.dot(eye),
    -zAxis.dot(eye),
    1.0, // Column 3 (Translation)
  );

  return lookAtMatrix;
}


Vector3 unProject(Vector4 ndcVector,Matrix4 inverseCombinedMatrix) {
  final Vector4 homogeneousCoords = inverseCombinedMatrix.transform(
    ndcVector,
  );

  // Unproject the point
  if (homogeneousCoords.w == 0.0) {
    // Avoid division by zero, indicates an invalid unprojection
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

Vector3 intersectRayWithPlane(Ray ray,Plane plane) {
  double denominator = plane.normal.dot(ray.direction);

  if (denominator.abs()  < 0.0001) {
    return Vector3.zero();
  }

  double t = -(plane.normal.dot(ray.origin) - plane.constant) / denominator;

  if (t >= 0.0 && t <= 1.0) {
    // Intersection point lies within the segment
    Vector3 intersectionPoint = ray.origin + (ray.direction * t);
    return intersectionPoint;
  }

  return Vector3.zero();
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