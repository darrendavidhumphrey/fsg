import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/vertex_buffer.dart';
import 'package:vector_math/vector_math_64.dart';

import 'float32_array_filler.dart';

class VertexAttributeCombination {
  int positionIndex;
  int texCoordIndex;
  int normalIndex;

  VertexAttributeCombination(
    this.positionIndex,
    this.texCoordIndex,
    this.normalIndex,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VertexAttributeCombination &&
          runtimeType == other.runtimeType &&
          positionIndex == other.positionIndex &&
          texCoordIndex == other.texCoordIndex &&
          normalIndex == other.normalIndex;

  @override
  int get hashCode => Object.hash(positionIndex, texCoordIndex, normalIndex);
}

class Face {
  List<int> corners; // A face is defined a list of corner indices

  Face(List<int> faceCorners) : corners = toTriangleIndices(faceCorners);

  // Wavefront objects can contain faces with more than 3 corners (n-gons).
  // This function converts an n-gon into a list of triangles using a simple
  // fan triangulation method, which works well for convex polygons.
  static List<int> toTriangleIndices(List<int> faceCorners) {
    if (faceCorners.length == 3) {
      return faceCorners;
    }

    List<int> result = [];

    for (int i = 0; i < faceCorners.length - 2; i++) {
      result.add(faceCorners[0]);
      result.add(faceCorners[i + 1]);
      result.add(faceCorners[i + 2]);
    }
    return result;
  }
}

class Mesh {
  String? materialName;
  final List<int> triangleIndices = [];
  final int bufferOffset;

  Mesh(List<Face> faces, {required this.bufferOffset, this.materialName}) {
    for (var face in faces) {
      triangleIndices.addAll(face.corners);
    }
  }
}

class WavefrontObjModel {
  late final VertexBuffer vertexBuffer;
  List<Mesh> meshes = [];
  final RenderingContext gl;

  // State for parsing
  List<Face> _currentMeshFaces = [];
  String _currentMaterialName = 'defaultMaterial';
  int _iboOffset = 0;

  void _finalizeCurrentMesh() {
    if (_currentMeshFaces.isNotEmpty) {
      final newMesh = Mesh(
        _currentMeshFaces,
        bufferOffset: _iboOffset,
        materialName: _currentMaterialName,
      );
      meshes.add(newMesh);
      _iboOffset += newMesh.triangleIndices.length;
      _currentMeshFaces = []; // Reset for the next mesh
    }
  }

  void loadFromString(String objFileContent) {
    List<Vector3> tempPositions = [];
    List<Vector2> tempTextureCoordinates = [];
    List<Vector3> tempNormals = [];

    HashMap<VertexAttributeCombination, int> uniqueVertexMap = HashMap();
    int nextAvailableIndex = 0;

    // Pre-scan to determine the number of unique vertices needed.
    // This is more efficient than incrementally growing the buffer.
    List<String> lines = LineSplitter().convert(objFileContent);
    for (String line in lines) {
      if (line.startsWith('f ')) {
        List<String> parts = line.split(' ');
        for (int i = 1; i < parts.length; i++) {
          List<String> indicesStr = parts[i].split('/');
          if (indicesStr.length == 3) {
            final combo = VertexAttributeCombination(
              int.parse(indicesStr[0]) - 1,
              int.parse(indicesStr[1]) - 1,
              int.parse(indicesStr[2]) - 1,
            );
            uniqueVertexMap.putIfAbsent(combo, () => nextAvailableIndex++);
          }
        }
      }
    }

    // Allocate the vertex buffer with the final size.
    vertexBuffer = VertexBuffer.v3t2n3(gl); // Assumes a global or passed-in GL context
    final vboData = vertexBuffer.requestBuffer(uniqueVertexMap.length)!;
    final filler = Float32ArrayFiller(vboData);

    // Reset state for the main parsing pass.
    uniqueVertexMap.clear();
    nextAvailableIndex = 0;

    for (String line in lines) {
      List<String> parts = line.split(' ');
      String prefix = parts[0];

      if (prefix == "v") {
        tempPositions.add(Vector3(
          double.parse(parts[1]),
          double.parse(parts[2]),
          double.parse(parts[3]),
        ));
      } else if (prefix == "vt") {
        tempTextureCoordinates.add(Vector2(
          double.parse(parts[1]),
          double.parse(parts[2]),
        ));
      } else if (prefix == "vn") {
        tempNormals.add(Vector3(
          double.parse(parts[1]),
          double.parse(parts[2]),
          double.parse(parts[3]),
        ));
      } else if (prefix == "usemtl") {
        _finalizeCurrentMesh();
        _currentMaterialName = parts[1];
      } else if (prefix == "f") {
        List<int> faceCorners = [];
        for (int i = 1; i < parts.length; i++) {
          List<String> indicesStr = parts[i].split('/');
          if (indicesStr.length == 3) {
            final currentCombination = VertexAttributeCombination(
              int.parse(indicesStr[0]) - 1,
              int.parse(indicesStr[1]) - 1,
              int.parse(indicesStr[2]) - 1,
            );

            if (!uniqueVertexMap.containsKey(currentCombination)) {
              final newIndex = nextAvailableIndex++;
              uniqueVertexMap[currentCombination] = newIndex;

              // Write vertex data directly to the Float32Array
              filler.addV3T2N3(
                tempPositions[currentCombination.positionIndex],
                tempTextureCoordinates[currentCombination.texCoordIndex],
                tempNormals[currentCombination.normalIndex],
              );
            }
            faceCorners.add(uniqueVertexMap[currentCombination]!);
          }
        }
        _currentMeshFaces.add(Face(faceCorners));
      } else if (prefix == "o" || prefix == "g") {
        _finalizeCurrentMesh();
      }
    }

    _finalizeCurrentMesh(); // Finalize the last mesh in the file
    vertexBuffer.setActiveVertexCount(uniqueVertexMap.length);
  }

  WavefrontObjModel(this.gl);

  /// Creates a [WavefrontObjModel] from an asset file.
  static Future<WavefrontObjModel> fromAsset(String assetPath,RenderingContext gl) async {
    try {
      final objFileContent = await rootBundle.loadString(assetPath);
      final objModel = WavefrontObjModel(gl);
      objModel.loadFromString(objFileContent);
      return objModel;
    } catch (e) {
      throw Exception('Failed to load OBJ asset from "$assetPath": $e');
    }
  }
}
