import 'dart:typed_data';

import 'package:flutter_angle/flutter_angle.dart';

class IndexBuffer {
  final RenderingContext _gl;
  final Buffer _iboId;

  int _activeIndexCount = 0;
  int _capacity = 0;
  int get indexCount => _activeIndexCount;

  Int16Array? _indexData;

  /// Creates an index buffer for the given rendering context.
  IndexBuffer(this._gl) : _iboId = _gl.createBuffer();

  /// Ensures the underlying buffer has at least [newIndexCount] capacity and
  /// returns it.
  ///
  /// The buffer will grow if the requested count is larger than the current
  /// capacity. It will shrink if the requested count is less than half the
  /// current capacity to save memory.
  Int16Array? requestBuffer(int newIndexCount) {
    final bool needsToReallocate =
        newIndexCount > _capacity || (newIndexCount < _capacity / 2);

    if (needsToReallocate) {
      // Dispose the old buffer if it exists.
      _indexData?.dispose();

      if (newIndexCount > 0) {
        _indexData = Int16Array(newIndexCount);
      } else {
        _indexData = null;
      }
      _capacity = newIndexCount;

      // Ensure the active count doesn't exceed the new, smaller capacity.
      if (_activeIndexCount > _capacity) {
        _activeIndexCount = _capacity;
      }
    }

    return _indexData;
  }

  /// Disposes of all WebGL resources and buffers held by this object.
  void dispose() {
    _gl.deleteBuffer(_iboId);
    _indexData?.dispose();
    _indexData = null;
  }

  /// Updates the GPU buffer with the data from the local [Int16Array] and
  /// sets the number of active indices to be drawn.
  void setActiveIndexCount(int count) {
    assert(count <= _capacity);
    _activeIndexCount = count;
    _gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _iboId);
    _gl.bufferData(WebGL.ELEMENT_ARRAY_BUFFER, _indexData, WebGL.STATIC_DRAW);
    _gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
  }

  /// Binds the index buffer to make it the active ELEMENT_ARRAY_BUFFER.
  void drawSetup() {
    _gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _iboId);
  }

  /// Unbinds the index buffer.
  void drawTeardown() {
    _gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
  }
}
