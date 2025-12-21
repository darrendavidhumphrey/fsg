import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/shaders/shaders.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'float32_array_filler.dart';

/// Represents the possible components a vertex can have.
/// Each component is associated with a specific, constant OpenGL attribute location.
enum VertexComponent {
  position(3, ShaderList.v3Attrib, 0), // Location 0, 3 floats
  normal(3, ShaderList.n3Attrib, 1), // Location 1, 3 floats
  texCoord(2, ShaderList.t2Attrib, 2), // Location 2, 2 floats
  color(4, ShaderList.c4Attrib, 3); // Location 3, 4 floats (RGBA)

  final int size; // Number of float components (e.g., 3 for vec3)
  final String shaderAttributeName;
  final int attributeLocation;

  const VertexComponent(
      this.size, this.shaderAttributeName, this.attributeLocation);

  /// Get the total size in bytes for this component.
  int get byteSize => size * Float32List.bytesPerElement;
}

/// A flag-based enum to specify which components are enabled.
/// This allows combining multiple components using bitwise operations.
class VertexComponentFlags {
  static const int none = 0;
  static const int position = 1 << 0;
  static const int normal = 1 << 1;
  static const int texCoord = 1 << 2;
  static const int color = 1 << 3;

  final int value;

  const VertexComponentFlags(this.value);

  bool contains(int other) {
    return (value & other) == other;
  }
}

class VertexBuffer {
  final RenderingContext _gl;
  final Buffer _vboId;
  final VertexComponentFlags enabledComponents;

  int _activeVertexCount = 0;
  int _capacity = 0;
  final int _stride; // Total bytes per vertex
  final int _componentCount; // Number of float components per vertex

  int get activeVertexCount => _activeVertexCount;
  int get capacity => _capacity;
  int get stride => _stride;
  int get componentCount => _componentCount;

  Float32Array? vertexData;

  VertexBuffer(this._gl, {required this.enabledComponents})
      : _vboId = _gl.createBuffer(),
        _stride = _calculateStride(enabledComponents),
        _componentCount = _calculateComponentCount(enabledComponents);

  VertexBuffer.v3c4(RenderingContext gl)
      : this(gl,
            enabledComponents: const VertexComponentFlags(
              VertexComponentFlags.position | VertexComponentFlags.color,
            ));

  VertexBuffer.v3t2(RenderingContext gl)
      : this(gl,
            enabledComponents: const VertexComponentFlags(
              VertexComponentFlags.position | VertexComponentFlags.texCoord,
            ));

  VertexBuffer.v3n3(RenderingContext gl)
      : this(gl,
            enabledComponents: const VertexComponentFlags(
              VertexComponentFlags.position | VertexComponentFlags.normal,
            ));

  VertexBuffer.v3t2n3(RenderingContext gl)
      : this(gl,
            enabledComponents: const VertexComponentFlags(
              VertexComponentFlags.position |
                  VertexComponentFlags.normal |
                  VertexComponentFlags.texCoord,
            ));

  void setActiveVertexCount(int count) {
    assert(count <= _capacity);
    _activeVertexCount = count;

    if ((_activeVertexCount > 0) && (vertexData != null)) {
      _gl.bindBuffer(WebGL.ARRAY_BUFFER, _vboId);
      _gl.bufferData(WebGL.ARRAY_BUFFER, vertexData, WebGL.STATIC_DRAW);
    }
  }

  Float32Array? requestBuffer(int newVertexCount) {
    final bool needsReallocation =
        newVertexCount > _capacity || (newVertexCount < _capacity / 2);

    if (needsReallocation) {
      vertexData?.dispose();
      vertexData = newVertexCount > 0
          ? Float32Array(newVertexCount * _componentCount)
          : null;
      _capacity = newVertexCount;

      if (_activeVertexCount > _capacity) {
        _activeVertexCount = _capacity;
      }
    }

    return vertexData;
  }

  void dispose() {
    _gl.deleteBuffer(_vboId);
    vertexData?.dispose();
    vertexData = null;
  }

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

  void enableComponents() {
    int offset = 0;

    if (enabledComponents.contains(VertexComponentFlags.position)) {
      final comp = VertexComponent.position;
      _gl.enableVertexAttribArray(comp.attributeLocation);
      _gl.vertexAttribPointer(
        comp.attributeLocation,
        comp.size,
        WebGL.FLOAT,
        false,
        _stride,
        offset,
      );
      offset += comp.byteSize;
    }

    if (enabledComponents.contains(VertexComponentFlags.normal)) {
      final comp = VertexComponent.normal;
      _gl.enableVertexAttribArray(comp.attributeLocation);
      _gl.vertexAttribPointer(
        comp.attributeLocation,
        comp.size,
        WebGL.FLOAT,
        false,
        _stride,
        offset,
      );
      offset += comp.byteSize;
    }

    if (enabledComponents.contains(VertexComponentFlags.texCoord)) {
      final comp = VertexComponent.texCoord;
      _gl.enableVertexAttribArray(comp.attributeLocation);
      _gl.vertexAttribPointer(
        comp.attributeLocation,
        comp.size,
        WebGL.FLOAT,
        false,
        _stride,
        offset,
      );
      offset += comp.byteSize;
    }

    if (enabledComponents.contains(VertexComponentFlags.color)) {
      final comp = VertexComponent.color;
      _gl.enableVertexAttribArray(comp.attributeLocation);
      _gl.vertexAttribPointer(
        comp.attributeLocation,
        comp.size,
        WebGL.FLOAT,
        false,
        _stride,
        offset,
      );
      offset += comp.byteSize;
    }
  }

  void disableComponents() {
    if (enabledComponents.contains(VertexComponentFlags.position)) {
      _gl.disableVertexAttribArray(VertexComponent.position.attributeLocation);
    }
    if (enabledComponents.contains(VertexComponentFlags.normal)) {
      _gl.disableVertexAttribArray(VertexComponent.normal.attributeLocation);
    }
    if (enabledComponents.contains(VertexComponentFlags.texCoord)) {
      _gl.disableVertexAttribArray(VertexComponent.texCoord.attributeLocation);
    }
    if (enabledComponents.contains(VertexComponentFlags.color)) {
      _gl.disableVertexAttribArray(VertexComponent.color.attributeLocation);
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
    _gl.bindBuffer(WebGL.ARRAY_BUFFER, _vboId);
  }

  void drawSetup() {
    _gl.bindBuffer(WebGL.ARRAY_BUFFER, _vboId);
    enableComponents();
    _gl.activeTexture(WebGL.TEXTURE0);
  }

  void drawTeardown() {
    disableComponents();
  }

  void drawTriangles() {
    if (activeVertexCount > 0) {
      _gl.drawArrays(WebGL.TRIANGLES, 0, activeVertexCount);
    }
  }
}
