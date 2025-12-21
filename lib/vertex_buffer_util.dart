import 'dart:ui';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';
import 'float32_array_filler.dart';
import 'polyline.dart';
import 'solid.dart';
import 'util.dart';
import 'vertex_buffer.dart';

extension SolidFiller on Solid {
  void addToVertexBuffer(VertexBuffer vbo) {
    // Calculate the total number of vertices in all faces
    // Each face has 2 triangles of 3 vertices each, so we multiply by 6
    int triangleCount = faces.length * 2;
    int vertexCount = triangleCount * 3;
    Float32Array? vertexTextureArray = vbo.requestBuffer(vertexCount)!;
    Float32ArrayFiller filler = Float32ArrayFiller(vertexTextureArray);

    for (var face in faces) {
      addTexturedTriFan(filler,face, true);
    }

    // Now update the VBO with the vertex data
    vbo.setActiveVertexCount(vertexCount);
  }
}

 void addColorTriFan(Float32ArrayFiller filler,Polyline outline,Color color) {
   int numTris = outline.length-2;
   Vector3 v0 = outline.getVector3(0);
   for (int j=0; j < numTris; j++) {
     Vector3 v1 = outline.getVector3(j+1);
     Vector3 v2 = outline.getVector3(j+2);
     filler.addV3C4(v0, color);
     filler.addV3C4(v1, color);
     filler.addV3C4(v2, color);
   }
 }

  void makeTessellatedColorOutlines(VertexBuffer vbo, List<Polyline> outlines,Color color) {
    int triangleCount = 0;

    // Count triangles in each outline
    for (int i = 0; i < outlines.length; i++) {
      if (outlines[i].length > 2) {
        triangleCount += (outlines[i].length - 2);
      }
    }

    int newVertexCount = triangleCount * 3;

    Float32Array? vertexTextureArray = vbo.requestBuffer(newVertexCount);

    // array will be null if 0 verts were requested
    if (vertexTextureArray != null) {
      Float32ArrayFiller filler = Float32ArrayFiller(vertexTextureArray);

      for (int i = 0; i < outlines.length; i++) {
        Polyline outline = outlines[i];
        if (outline.length < 3) {
          continue;
        }
        addColorTriFan(filler,outline,color);
      }
    }

    vbo.setActiveVertexCount(newVertexCount);
  }
void addTexturedTriFan(Float32ArrayFiller filler,Polyline outline,bool generateNormals) {
  int numTris = outline.length-2;
  Vector3 v0 = outline.getVector3(0);
  Vector3 normal = Vector3.zero();

  if (outline.planeIsValid) {
    normal = outline.plane.normal;
  }

  final bounds = outline.getBounds2D();
  double w = bounds.max.x - bounds.min.x;
  double h = bounds.max.y - bounds.min.y;
  double x = bounds.min.x;
  double y = bounds.min.y;

  for (int j=0; j < numTris; j++) {
    Vector3 v1 = outline.getVector3(j+1);
    Vector3 v2 = outline.getVector3(j+2);

    List<Vector2> texCoord = computeTexCoords(
      v0, v1, v2,
      x,
      y,
      w,
      h,
    );

    if (generateNormals) {
      filler.addV3T2N3(v0, texCoord[0], normal);
      filler.addV3T2N3(v1, texCoord[1], normal);
      filler.addV3T2N3(v2, texCoord[2], normal);
    } else {
      filler.addV3V2(v0, texCoord[0]);
      filler.addV3V2(v1, texCoord[1]);
      filler.addV3V2(v2, texCoord[2]);
    }
  }
}

  void tesselateOutlines(VertexBuffer vbo, List<Polyline> outlines,bool generateNormals) {
    int triangleCount = 0;

    // Count triangles in each outline
    for (int i = 0; i < outlines.length; i++) {
      if (outlines[i].length > 2) {
        triangleCount += (outlines[i].length - 2);
      }
    }

    int newVertexCount = triangleCount * 3;

    Float32Array? vertexTextureArray = vbo.requestBuffer(newVertexCount);

    // array will be null if 0 verts were requested
    if (vertexTextureArray != null) {
      Float32ArrayFiller filler = Float32ArrayFiller(vertexTextureArray);

      for (int i = 0; i < outlines.length; i++) {
        Polyline outline = outlines[i];

        addTexturedTriFan(filler,outline,generateNormals);
      }
    }

    vbo.setActiveVertexCount(newVertexCount);
  }


  /* // TODO deprecated
  void addToVbo(
    Float32ArrayFiller filler,
    VertexBuffer vbo,
    bool generateNormals,
  ) {
    // Get mesh extents
    List<Vector3> bounds = getBounds();
    double w = bounds[1].x - bounds[0].x;
    double h = bounds[1].y - bounds[0].y;
    double x = bounds[0].x;
    double y = bounds[0].y;

    for (var tri in triangles) {
      List<Vector2> texCoord = computeTexCoords(tri, x, y, w, h);
      texCoord = [
        Vector2(tri.point0.x, tri.point0.y),
        Vector2(tri.point1.x, tri.point1.y),
        Vector2(tri.point2.x, tri.point2.y),
      ];

      if (generateNormals) {
        Vector3 normal = Vector3.zero();
        tri.copyNormalInto(normal);

        filler.addV3T2N3(tri.point0, texCoord[0], normal);
        filler.addV3T2N3(tri.point1, texCoord[1], normal);
        filler.addV3T2N3(tri.point2, texCoord[2], normal);
      } else {
        filler.addV3V2(tri.point0, texCoord[0]);
        filler.addV3V2(tri.point1, texCoord[1]);
        filler.addV3V2(tri.point2, texCoord[2]);
      }
    }
  }

*/
