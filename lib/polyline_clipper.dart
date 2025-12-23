import 'package:fsg/polyline.dart';
import 'package:vector_math/vector_math_64.dart';

// Implementation of the Cyrus-Beck line clipping algorithm for a 2D convex polygon.

/// Represents one edge of the convex clipping polygon, defined by a point on the
/// edge and an outward-pointing normal vector.
class ClipEdge {
  /// The normal vector of the edge, pointing away from the clip region's interior.
  final Vector2 normal;

  /// Any point that lies on the infinite line defined by the edge.
  final Vector2 pointOnEdge;

  ClipEdge(this.normal, this.pointOnEdge);
}

/// A class that clips a [Polyline] against a rectangular boundary using the
/// Cyrus-Beck algorithm.
class PolylineClipper {
  /// The list of clipping edges that define the clipping boundary.
  final List<ClipEdge> clipEdges;
  static const double epsilon = 1e-4;

  /// Precomputes the four clipping edges from the boundaries of a rectangle.
  /// Assumes a Y-up coordinate system where `top` > `bottom`.
  static List<ClipEdge> _precomputeClipEdgesFromRect(
    double left,
    double top, // The maximum Y value
    double right,
    double bottom, // The minimum Y value
  ) {
    return [
      // Left edge, normal points left (outward).
      ClipEdge(Vector2(-1.0, 0.0), Vector2(left, top)),
      // Bottom edge, normal points down (outward).
      ClipEdge(Vector2(0.0, -1.0), Vector2(left, bottom)),
      // Right edge, normal points right (outward).
      ClipEdge(Vector2(1.0, 0.0), Vector2(right, top)),
      // Top edge, normal points up (outward).
      ClipEdge(Vector2(0.0, 1.0), Vector2(left, top)),
    ];
  }

  /// Clips a single line segment against a set of convex clipping planes.
  ///
  /// This implementation assumes the clipping planes have outward-pointing normals.
  List<Vector2>? _clipSegment(
      Vector2 p0, Vector2 p1, List<ClipEdge> clipPlanes) {
    double tE = 0.0; // The largest t-value for an "entering" intersection.
    double tL = 1.0; // The smallest t-value for a "leaving" intersection.

    final direction = p1 - p0;

    if (direction.length2 < epsilon) {
      // The segment is a point. Check if it's inside all clip planes.
      for (final clipPlane in clipPlanes) {
        // With outward normals, a positive dot product means the point is outside.
        if (clipPlane.normal.dot(p0 - clipPlane.pointOnEdge) > 0) {
          return null; // Point is outside.
        }
      }
      return [p0, p0]; // Point is inside.
    }

    for (final clipPlane in clipPlanes) {
      final numerator = clipPlane.normal.dot(p0 - clipPlane.pointOnEdge);
      final denominator = clipPlane.normal.dot(direction);

      if (denominator.abs() < epsilon) {
        // Line is parallel to the clipping edge.
        // If the numerator is positive, the line is parallel and outside.
        if (numerator > 0) {
          return null;
        }
        continue; // Parallel and inside.
      }

      final t = -numerator / denominator;

      // --- Logic for Outward-Facing Normals ---
      if (denominator > 0) {
        // The line segment is heading "out" of this edge (leaving).
        // We are interested in the smallest leaving t-value.
        tL = tL < t ? tL : t; // tL = min(tL, t)
      } else {
        // The line segment is heading "in" across this edge (entering).
        // We are interested in the largest entering t-value.
        tE = tE > t ? tE : t; // tE = max(tE, t)
      }
    }

    // If the entering t-value is after the leaving t-value, the segment is entirely outside.
    if (tE > tL) {
      return null;
    }

    // Calculate the clipped segment endpoints from the final t-values.
    final clippedP0 = p0 + direction * tE;
    final clippedP1 = p0 + direction * tL;
    return [clippedP0, clippedP1];
  }

  /// Clips a closed polyline against the precomputed clipping edges.
  Polyline? clip(Polyline polyline) {
    if (polyline.length < 3) {
      return null;
    }

    List<Vector2> clippedVertices = [];
    final double epsilonSq = epsilon * epsilon;

    // Iterate over all edges of the closed polyline, including the closing edge.
    for (int i = 0; i < polyline.length; i++) {
      Vector2 p0 = polyline.getVector2(i);
      Vector2 p1 = polyline.getVector2((i + 1) % polyline.length);

      List<Vector2>? clippedSegment = _clipSegment(p0, p1, clipEdges);

      if (clippedSegment != null) {
        // Add the start point of the clipped segment, but only if it's not a
        // duplicate of the previously added point. This prevents degenerate micro-edges.
        if (clippedVertices.isEmpty ||
            (clippedVertices.last - clippedSegment.first).length2 > epsilonSq) {
          clippedVertices.add(clippedSegment.first);
        }
        // Always add the end point of the segment. The next iteration will handle
        // de-duplication if its start point is the same.
        clippedVertices.add(clippedSegment.last);
      }
    }

    if (clippedVertices.length < 3) {
      return null;
    }

    // The clipping process can create collinear or duplicate points. Clean them up.
    Polyline tempResult = Polyline.fromVector2(clippedVertices);
    List<int> validIndices = tempResult.getValidVertexIndices();

    if (validIndices.length < 3) {
      return null;
    }

    // If vertices were removed, create a final, corrected polyline.
    if (validIndices.length < tempResult.length) {
      return Polyline.fromIndices(tempResult, validIndices);
    } else {
      // Otherwise, the result is already clean and valid.
      return tempResult.planeIsValid ? tempResult : null;
    }
  }

  /// Creates a clipper for a given rectangular boundary in a Y-up coordinate system.
  PolylineClipper({required double left, required double bottom, required double right, required double top})
      : clipEdges = _precomputeClipEdgesFromRect(left, top, right, bottom);
}
