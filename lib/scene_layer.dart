import 'dart:ui';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';
import 'scene.dart';

/// An abstract base class for a layer within a [Scene].
///
/// A layer is a distinct component of a scene that can be rebuilt and drawn
/// independently. It has its own lifecycle methods and manages its own WebGL
/// resources. This class must be initialized with a rendering context via [init]
/// before it can be used.
abstract class SceneLayer {
  /// A reference to the parent [Scene] that owns this layer.
  late Scene parent;

  /// The WebGL rendering context.
  late RenderingContext gl;

  bool _needsRebuild = true;

  /// A flag indicating whether the layer needs to have its resources or geometry
  /// rebuilt on the next frame.
  bool get needsRebuild => _needsRebuild;

  bool _isInitialized = false;

  /// A flag indicating whether the layer has been initialized with a rendering context.
  bool get isInitialized => _isInitialized;

  /// Creates a new SceneLayer.
  SceneLayer();

  /// The current size of the viewport, passed down from the parent scene.
  Size _viewportSize = Size.zero;
  Size get viewportSize => _viewportSize;

  /// Sets the viewport size for this layer.
  void setViewportSize(Size size) {
    _viewportSize = size;
  }

  /// Sets the rebuild flag for this layer.
  void setNeedsRebuild(bool value) {
    _needsRebuild = value;
  }

  /// Initializes the layer with the WebGL [RenderingContext].
  /// This must be called before any drawing or building operations can occur.
  void init(Scene parent) {
    this.parent = parent;
    gl = parent.gl;
  }

  /// Rebuilds the layer's internal state and WebGL resources.
  ///
  /// Subclasses must implement this method to handle tasks like creating VBOs,
  /// uploading data, or performing calculations that only need to happen when
  /// state changes.
  void rebuild(DateTime now);

  /// Sets the initialization status of the layer.
  void setInitialized(bool value) {
    _isInitialized = value;
  }

  /// Draws the layer.
  ///
  /// Subclasses must implement this method to define their rendering logic using
  /// the provided projection [pMatrix] and model-view [mvMatrix].
  void draw(Matrix4 pMatrix, Matrix4 mvMatrix);

  /// Releases any WebGL resources held by this layer.
  ///
  /// Subclasses should override this to delete buffers, textures, shaders, etc.,
  /// to prevent memory leaks.
  void dispose() {}
}
