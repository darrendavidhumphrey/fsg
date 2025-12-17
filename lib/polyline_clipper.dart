
import 'package:flutter_angle_jig/polyline.dart';
import 'package:vector_math/vector_math_64.dart';

// Implementation of Cyrus-Beck line clipping
class ClipEdge {
  Vector2 normal;
  Vector2 pointOnEdge;

  ClipEdge(this.normal, this.pointOnEdge);
}

class PolylineClipper {
  late List<ClipEdge> clipEdges;
  static const double epsilon = 1e-4;
  // Function to precompute the clipping edges from top, left, right, and bottom coordinates
  List<ClipEdge> precomputeClipEdgesFromRect(
      double left,
      double top,
      double right,
      double bottom,
      ) {
    List<ClipEdge> edges = [];

    // Define the 4 corners of the rectangle
    Vector2 topEdge = Vector2(left, top);
    Vector2 leftEdge = Vector2(left, bottom);
    Vector2 rightEdge = Vector2(right, bottom);
    Vector2 bottomEdge = Vector2(left, bottom);

    // Add edges (in a consistent order, e.g., counter-clockwise)
    // Left edge
    edges.add(ClipEdge(Vector2(-1.0, 0.0), leftEdge)); // Normal pointing left


    // Bottom edge
    edges.add(ClipEdge(Vector2(0.0, -1.0), bottomEdge)); // Normal pointing down

    // Right edge
    edges.add(
      ClipEdge(Vector2(1.0, 0.0), rightEdge),
    ); // Normal pointing right

    // Top edge
    edges.add(
      ClipEdge(Vector2(0.0, 1.0), topEdge),
    ); // Normal pointing up

    return edges;
  }


  List<Vector2>? cyrusBeckClipSegment(
      Vector2 p0, Vector2 p1, List<ClipEdge> clipPlanes) {
    double tE = 0.0; // Entering parameter
    double tL = 1.0; // Leaving parameter

    final direction = p1 - p0; // Direction vector of the line

    // Handle the case where the line segment is a single point or degenerate
    if (direction.length2 < epsilon) { // If the squared length is very small, treat as a point
      bool inside = true;
      for (final clipPlane in clipPlanes) {
        if (clipPlane.normal.dot(p0 - clipPlane.pointOnEdge) < -epsilon) {
          inside = false;
          break;
        }
      }
      return inside ? [p0, p0] : null; // Return the point if inside, or null if outside
    }

    for (final clipPlane in clipPlanes) {
      final normal = clipPlane.normal;
      final pointOnPlane = clipPlane.pointOnEdge;

      final numerator = normal.dot(p0 - pointOnPlane);
      final denominator = normal.dot(direction);

      // If the line is parallel to the clipping plane
      if (denominator.abs() < epsilon) {
        if (numerator > epsilon) {
          // Line is outside the clipping window, parallel to this edge
          return null;
        }
        // If numerator is >= -epsilon, line is inside or on the plane
        // (within epsilon tolerance), and parallel to it, so continue.
        continue;
      }

      final t = -numerator / denominator;

      if (denominator < -epsilon) { // Potential entering point
        tE = tE > t ? tE : t; // Equivalent to tE = max(tE, t)
      } else { // Potential leaving point
        tL = tL < t ? tL : t; // Equivalent to tL = min(tL, t)
      }

      if (tE > tL + epsilon) { // If tE is significantly greater than tL, completely outside
        return null;
      }
    }

    // If we reach here, the line segment is at least partially visible
    if (tE <= tL + epsilon) {
      final clippedP0 = p0 + direction * tE;
      final clippedP1 = p0 + direction * tL;
      return [clippedP0, clippedP1];
    } else {
      // This case should ideally be caught by the tE > tL + EPSILON check
      return null;
    }
  }

  Polyline? cyrusBeckClipPolyline(Polyline polyline) {

    // Reject degenerate polyline
    if (polyline.length < 3) {
      return null;
    }

    List<Vector2> clippedPolyline = [];

    final double epsilonSq = epsilon*epsilon;
    for (int i = 0; i < polyline.length-1; i++) {
      Vector2 p0 = polyline.getVector2(i);
      Vector2 p1 = polyline.getVector2(i + 1);

      List<Vector2>? clippedSegment = cyrusBeckClipSegment(p0, p1, clipEdges);

      if (clippedSegment != null) {
        // Add the first point of the clipped segment if it's the start of the clipped polyline
        // or if it's a new point and not extremely close to the last added point
        if (clippedPolyline.isEmpty || (clippedPolyline.last - clippedSegment.first).length2 > epsilonSq) {
          clippedPolyline.add(clippedSegment.first);
        }
        // Add the second point of the clipped segment if it's a new point and not extremely close to the last added point
        if ((clippedPolyline.last - clippedSegment.last).length2 > epsilonSq) {
          clippedPolyline.add(clippedSegment.last);
        }
      }
    }

    // If the clipped polyline is empty, there's no point in continuing
    if (clippedPolyline.isEmpty) {
      return null;
    }

    // Handle closing the polyline if requested
    Vector2 firstPoint = polyline.getVector2(0);
    Vector2 lastPoint = polyline.getVector2(polyline.length - 1);

    List<Vector2>? closingSegment = cyrusBeckClipSegment(lastPoint, firstPoint, clipEdges);

    if (closingSegment != null) {
      // If the first point of the closing segment is different from the last point already added
      if ((clippedPolyline.last - closingSegment.first).length2 > epsilonSq) {
        clippedPolyline.add(closingSegment.first);
      }

      // If the second point of the closing segment is different from the first point of the clipped polyline
      // This effectively closes the clipped polyline
      if ((clippedPolyline.first - closingSegment.last).length2 > epsilonSq) {
        // We only add the second point if it's not already the first point of the clipped polyline
        // This implicitly closes the shape visually without adding a duplicate point
        // If the resulting clipped polyline is just two points, it's a line segment, not a closed shape.
        // We ensure we don't add the first point again if it's the *same* as the last point of the closing segment.
        clippedPolyline.add(closingSegment.last);
      }

    }

    if (clippedPolyline.isEmpty) {
      return null;
    }

    // Don't return degenerate polyline
    if (clippedPolyline.length < 3) {
      return null;
    }

    Polyline result = Polyline.fromVector2(clippedPolyline);
    result.setPlane();
    if (!result.planeIsValid) {
      return null;
    }

    // Get the list of good vertices
    List<int> indices = result.testForDegenerateVertices();

    // If length not the same, then there were degenerate vertices
    if (indices.length != result.length) {
      if (indices.length <3 ) {
        return null;
      }
      Polyline correctedResult = Polyline.fromDegenerate(result, indices);
      if (!correctedResult.planeIsValid) {
        return null;
      }
      return correctedResult;
    }

    return result;
  }

  PolylineClipper(double left, double top, double right, double bottom) {
    clipEdges = precomputeClipEdgesFromRect(left, top, right, bottom);
  }
}
