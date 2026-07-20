import 'package:flutter_angle/flutter_angle.dart';

/// A mixin to manage the lifecycle of a WebGL RenderingContext.
///
/// It provides a safe, guarded getter for the `gl` context and handles the
/// late initialization pattern, preventing use-before-init errors.
mixin GlContextManager {
  late RenderingContext _gl;
  bool _isInitialized = false;

  /// The WebGL rendering context.
  ///
  /// Throws a [StateError] if accessed before this object has been initialized.
  RenderingContext get gl {
    if (!_isInitialized) {
      throw StateError(
          '${runtimeType.toString()} GL context accessed before it was initialized.');
    }
    return _gl;
  }

  /// A flag indicating whether this object has been initialized with a rendering context.
  bool get isInitialized => _isInitialized;

  /// Initializes the object with the WebGL [RenderingContext].
  ///
  /// This must be called once before any other methods that access `gl` are used.
  /// This method is idempotent and safe to call multiple times.
  void initializeGl(RenderingContext gl) {
    if (_isInitialized) return;

    _gl = gl;
    _isInitialized = true;
  }
}
