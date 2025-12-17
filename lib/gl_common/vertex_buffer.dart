import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:flutter_angle_jig/gl_common/shaders/shaders.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../float32_array_filler.dart';

/// Represents the possible components a vertex can have.
/// Each component is associated with an OpenGL attribute location.
enum VertexComponent {
  position(3, ShaderList.v3Attrib), // Location 0, 3 floats,
  normal(3, ShaderList.n3Attrib), // Location 1, 3 floats,
  texCoord(2, ShaderList.t2Attrib), // Location 2, 2 floats
  color(4, ShaderList.c4Attrib); // Location 3, 4 floats (RGBA)

  final int size; // Number of float components (e.g., 3 for vec3)
  final String shaderAttributeName;

  const VertexComponent(this.size, this.shaderAttributeName);

  /// Get the total size in bytes for this component.
  int get byteSize => size * Float32List.bytesPerElement;
}

/// A flag-based enum to specify which components are enabled.
/// This allows combining multiple components using bitwise operations.
class VertexComponentFlags {
  static const int none = 0;
  static const int position = 0;
  static const int normal = (1 << 1);
  static const int texCoord = (1 << 2);
  static const int color = (1 << 3);

  final int value;

  const VertexComponentFlags(this.value);

  // Helper method to check if a flag is included
  bool contains(int other) {
    return (value & other) == other;
  }
}

class VertexBuffer {
  Buffer? _vboId; // OpenGL Vertex Buffer Object ID
  RenderingContext? _gl;
  bool _isInitialized = false;

  final VertexComponentFlags enabledComponents;
  int _activeVertexCount = 0;
  int _allocatedVertexCount = 0;
  int get allocatedVertexCount => _allocatedVertexCount;

  int get activeVertexCount => _activeVertexCount;
  late int _stride; // Total bytes per vertex
  int get stride => _stride;

  late int _componentCount; // Number of float components per vertex
  int get componentCount => _componentCount;

  Float32Array? vertexData;

  /// Constructor for creating an OpenGLVertexBuffer.
  ///
  /// [enabledComponents]: A bitmask of [VertexComponentFlags] to specify which components are included.
  VertexBuffer({required this.enabledComponents}) {
    _stride = _calculateStride(enabledComponents);
    _componentCount = _calculateComponentCount(enabledComponents);
    clearVertexData();
  }

  VertexBuffer.v3c4()
    : this(
        enabledComponents: VertexComponentFlags(
          VertexComponentFlags.position | VertexComponentFlags.color,
        ),
      );

  VertexBuffer.v3t2()
    : this(
        enabledComponents: VertexComponentFlags(
          VertexComponentFlags.position | VertexComponentFlags.texCoord,
        ),
      );

  VertexBuffer.v3n3()
    : this(
        enabledComponents: VertexComponentFlags(
          VertexComponentFlags.position | VertexComponentFlags.normal,
        ),
      );

  VertexBuffer.v3t2n3()
    : this(
        enabledComponents: VertexComponentFlags(
          VertexComponentFlags.position |
              VertexComponentFlags.normal |
              VertexComponentFlags.texCoord,
        ),
      );

  void setActiveVertexCount(int count) {
    assert(count <= _allocatedVertexCount);
    _activeVertexCount = count;

    if ((_activeVertexCount > 0) && (vertexData != null)) {
      _gl!.bindBuffer(WebGL.ARRAY_BUFFER, _vboId);
      _gl!.bufferData(WebGL.ARRAY_BUFFER, vertexData, WebGL.STATIC_DRAW);
    }
  }

  Float32Array? requestBuffer(int newVertexCount) {
    bool needsToGrow = (newVertexCount > _allocatedVertexCount);

    bool needsToShrink =
        (vertexData != null) && (newVertexCount < _allocatedVertexCount / 2);

    bool needsToFreeBuffer =
        (needsToGrow || needsToShrink) && (vertexData != null);

    if (needsToFreeBuffer) {
      vertexData!.dispose();
    }
    bool needsToAlloc = (needsToGrow || needsToShrink);

    if (needsToAlloc) {
      if (newVertexCount > 0) {
        vertexData = Float32Array(newVertexCount * _componentCount);
      } else {
        vertexData = null;
      }
    }
    _allocatedVertexCount = newVertexCount;

    // Ensure vertices stay in range when the buffer shrinks
    if (needsToShrink) {
      _activeVertexCount = newVertexCount;
    }

    return vertexData;
  }

  void clearVertexData() {
    _activeVertexCount = 0;
    if (vertexData != null) {
      vertexData!.dispose();
    }
    vertexData = null;
  }

  void init(RenderingContext gl) {
    assert(!_isInitialized);
    _gl = gl;
    _vboId = _gl!.createBuffer();

    _isInitialized = true;
  }

  void dispose() {
    if (_vboId != null) {
      _gl!.deleteBuffer(_vboId!);
    }
    clearVertexData();
  }

  /// Calculates the total stride (bytes per vertex) based on enabled components.
  static int _calculateStride(VertexComponentFlags flags) {
    int calculatedStride = 0;
    if (flags.contains(VertexComponentFlags.position)) {
      calculatedStride += VertexComponent.position.byteSize;
    }
    if (flags.contains(VertexComponentFlags.normal)) {
      calculatedStride += VertexComponent.normal.byteSize;
    }
    if (flags.contains(VertexComponentFlags.texCoord)) {
      calculatedStride += VertexComponent.texCoord.byteSize;
    }
    if (flags.contains(VertexComponentFlags.color)) {
      calculatedStride += VertexComponent.color.byteSize;
    }
    return calculatedStride;
  }

  static int _calculateComponentCount(VertexComponentFlags flags) {
    int count = 0;
    if (flags.contains(VertexComponentFlags.position)) {
      count += VertexComponent.position.size;
    }
    if (flags.contains(VertexComponentFlags.normal)) {
      count += VertexComponent.normal.size;
    }
    if (flags.contains(VertexComponentFlags.texCoord)) {
      count += VertexComponent.texCoord.size;
    }
    if (flags.contains(VertexComponentFlags.color)) {
      count += VertexComponent.color.size;
    }
    return count;
  }

  // Enable the vertex components that are enabled
  void enableComponents() {
    // Configure vertex attribute pointers based on enabled components
    int offset = 0; // Current byte offset into the vertex data

    // Dynamically assign attribute positions based on which attributes are present
    // NOTE: This code assumes that shaders always declare attributes in the same order

    int attribPosition = 0;

    if (enabledComponents.contains(VertexComponentFlags.position)) {
      _gl!.enableVertexAttribArray(attribPosition);
      _gl!.vertexAttribPointer(
        attribPosition,
        VertexComponent.position.size,
        WebGL.FLOAT,
        false,
        _stride, // Total bytes per vertex
        offset, // Byte offset for this attribute
      );

      offset += VertexComponent.position.byteSize;
      attribPosition++;
    }

    if (enabledComponents.contains(VertexComponentFlags.texCoord)) {
      _gl!.enableVertexAttribArray(attribPosition);

      _gl!.vertexAttribPointer(
        attribPosition,
        VertexComponent.texCoord.size,
        WebGL.FLOAT,
        false,
        _stride,
        offset,
      );
      offset += VertexComponent.texCoord.byteSize;
      attribPosition++;
    }

    if (enabledComponents.contains(VertexComponentFlags.normal)) {
      _gl!.enableVertexAttribArray(attribPosition);

      _gl!.vertexAttribPointer(
        attribPosition,
        VertexComponent.normal.size,
        WebGL.FLOAT,
        false,
        _stride,
        offset,
      );
      offset += VertexComponent.normal.byteSize;
      attribPosition++;
    }

    if (enabledComponents.contains(VertexComponentFlags.color)) {
      _gl!.enableVertexAttribArray(attribPosition);
      _gl!.vertexAttribPointer(
        attribPosition++,
        VertexComponent.color.size,
        WebGL.FLOAT, // Colors are floats (0.0-1.0)
        false,
        _stride,
        offset,
      );

      offset += VertexComponent.color.byteSize;
      attribPosition++;
    }
  }

  void disableComponents() {
    int attribPosition = 0;
    if (enabledComponents.contains(VertexComponentFlags.position)) {
      _gl!.disableVertexAttribArray(attribPosition);
      attribPosition++;
    }
    if (enabledComponents.contains(VertexComponentFlags.texCoord)) {
      _gl!.disableVertexAttribArray(attribPosition);
      attribPosition++;
    }
    if (enabledComponents.contains(VertexComponentFlags.normal)) {
      _gl!.disableVertexAttribArray(attribPosition);
      attribPosition++;
    }
    if (enabledComponents.contains(VertexComponentFlags.color)) {
      _gl!.disableVertexAttribArray(attribPosition);
      attribPosition++;
    }
  }

  void makeTexturedUnitQuad(Rect r, double z) {
    int newVertexCount = 6;

    Float32Array vertTextureArray = requestBuffer(newVertexCount)!;
    Float32ArrayFiller filler = Float32ArrayFiller(vertTextureArray);

    Rect tr = Rect.fromLTWH(0, 0, 1, 1);

    Quad q = Quad.points(
      Vector3(r.left, r.bottom, z),
      Vector3(r.right, r.bottom, z),
      Vector3(r.right, r.top, z),
      Vector3(r.left, r.top, z),
    );

    filler.addTexturedQuad(q, tr);
    setActiveVertexCount(newVertexCount);
  }

  void bindVbo() {
    _gl!.bindBuffer(WebGL.ARRAY_BUFFER, _vboId);
  }

  void drawSetup() {
    _gl!.bindBuffer(WebGL.ARRAY_BUFFER, _vboId);
    enableComponents();
    _gl!.activeTexture(WebGL.TEXTURE0);
  }

  void drawTeardown() {
    disableComponents();
  }

  void drawTriangles() {
    if (activeVertexCount > 0) {
      _gl!.drawArrays(WebGL.TRIANGLES, 0, activeVertexCount);
    }
  }
}
