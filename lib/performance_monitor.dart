import 'logging.dart';

class PerformanceMonitor with LoggableClass {
  final Stopwatch _stopwatch = Stopwatch();
  int _frameCount = 0;  int _totalMicroseconds = 0;
  bool timingEnabled = true;

  final String _tag;

  PerformanceMonitor({String? tag}) : _tag = tag ?? "PerformanceMonitor";

  void beginFrame() {
    if (!timingEnabled) return;
    _stopwatch..reset()..start();
  }

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