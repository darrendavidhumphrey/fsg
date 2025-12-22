import 'logging.dart';

/// A helper class to measure and report performance metrics, such as frame time.
///
/// This class uses a [Stopwatch] to time operations between [beginFrame] and
/// [endFrame] calls. After a set number of frames (e.g., 100), it calculates
/// and logs the average time, providing a simple way to monitor performance
/// over a moving window.
class PerformanceMonitor with LoggableClass {
  /// The internal stopwatch used to time each frame.
  final Stopwatch _stopwatch = Stopwatch();

  /// The number of frames that have been recorded since the last log.
  int _frameCount = 0;

  /// The accumulated time in microseconds for the current batch of frames.
  int _totalMicroseconds = 0;

  /// A flag to easily enable or disable performance monitoring at runtime.
  bool timingEnabled = true;

  /// An optional tag used to identify this monitor in log messages.
  final String _tag;

  /// Creates a performance monitor.
  ///
  /// An optional [tag] can be provided to distinguish its log output from
  /// other monitors.
  PerformanceMonitor({String? tag}) : _tag = tag ?? "PerformanceMonitor";

  /// Starts or resets the stopwatch to mark the beginning of a frame measurement.
  void beginFrame() {
    if (!timingEnabled) return;
    _stopwatch
      ..reset()
      ..start();
  }

  /// Stops the stopwatch to mark the end of a frame and updates the statistics.
  ///
  /// After 100 frames, this method calculates the average frame time and logs it
  /// before resetting the counters.
  void endFrame() {
    if (!timingEnabled) return;
    _totalMicroseconds += _stopwatch.elapsedMicroseconds;
    _frameCount++;

    if (_frameCount == 100) {
      double averageMilliseconds = (_totalMicroseconds / _frameCount) / 1000.0;
      logPedantic("{$_tag} Avg draw time: ${averageMilliseconds.toStringAsFixed(2)} ms");
      _frameCount = 0;
      _totalMicroseconds = 0;
    }
  }
}
