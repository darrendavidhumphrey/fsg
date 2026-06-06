/// This logging framework handles logging with different severity levels
/// and tracks the source of each log message from the class that emitted the
/// log message. The frame also allows for dynamic runtime filtering of log
/// events by level and by source. Additionally, it supports redirecting the
/// log messages to other sources besides the console.
library;

/// Defines the severity levels for log messages, in priority order.
///
/// When a log level is set for a source, only messages with that level or a
/// higher priority (a lower index) will be shown.
/// e.g. if the level is set to `warning`, only `error` and `warning` messages
/// will be logged.
enum LogLevel {
  /// No log messages will be shown.
  none,

  /// For critical errors that might prevent the application from running correctly.
  error,

  /// For potential issues or non-critical errors.
  warning,

  /// For general informational messages about application state.
  info,

  /// For detailed messages that are useful for debugging.
  verbose,

  /// For fine-grained messages, often used for tracing execution flow.
  trace,

  /// For extremely detailed or frequent messages, typically only used for deep
  /// debugging of specific components.
  pedantic,
}

/// Defines how detailed log messages should be when formatted.
enum Brevity {
  /// Displays only the log message itself.
  terse,

  /// Displays the severity level along with the message.
  normal,

  /// Displays the source, severity level, and the message.
  detailed,
}

/// A mixin that provides logging capabilities to any class.
///
/// By using this mixin on a class, you can call logging methods like `logError`,
/// `logWarning`, etc., and the source of the message will be automatically
/// set to the class's runtime type.
mixin class LoggableClass {
  String? _cachedRuntimeType;

  /// Log a message with the specified severity level.
  void log(LogLevel level, String message) {
    _cachedRuntimeType ??= runtimeType.toString();
    Logging._logMessage(level, _cachedRuntimeType!, message);
  }

  /// Logs a message with severity level [LogLevel.error].
  void logError(String message) => log(LogLevel.error, message);

  /// Logs a message with severity level [LogLevel.warning].
  void logWarning(String message) => log(LogLevel.warning, message);

  /// Logs a message with severity level [LogLevel.info].
  void logInfo(String message) => log(LogLevel.info, message);

  /// Logs a message with severity level [LogLevel.verbose].
  void logVerbose(String message) => log(LogLevel.verbose, message);

  /// Logs a message with severity level [LogLevel.trace].
  void logTrace(String message) => log(LogLevel.trace, message);

  /// Logs a message with severity level [LogLevel.pedantic].
  void logPedantic(String message) => log(LogLevel.pedantic, message);
}

/// A static utility class for configuring and creating log messages.
///
/// This class contains only static fields and methods and is not meant to be
/// instantiated.
class Logging {
  // Private constructor to prevent instantiation.
  Logging._();

  /// A map that stores the specific [LogLevel] for different sources (class names).
  /// If a source is not in this map, the [defaultLogLevel] is used.
  static Map<String, LogLevel> logLevelMap = {};

  /// The global brevity setting that controls the detail level of all log messages.
  static Brevity brevity = Brevity.normal;

  /// If true, console output will be color-coded based on log level.
  /// This uses ANSI escape codes and works in most modern terminals.
  static bool colorizeOutput = true;

  /// The log level for sources that have not specified their own filter level
  /// in the [logLevelMap].
  static LogLevel defaultLogLevel = LogLevel.pedantic;

  /// Installs a function that will receive all formatted log messages.
  /// Call this function with null will disable console logging.
  static void setConsoleLogFunction(void Function(String arg)? func) {
    _consoleLogFunction = func;
  }

  /// Installs an optional second function to receive log messages.
  /// This is useful for redirecting logs to a UI widget, a file, or a network service.
  /// The custom log function happens independently of the console log function.
  static void setCustomLogFunction(void Function(String arg) func) {
    _customLogFunction = func;
  }

  /// Sets the log level for a specific [source] using a string representation
  /// of a [LogLevel] (e.g., "warning").
  ///
  /// If the [level] string is invalid, a warning is logged and the default
  /// log level is used for that source.
  static void setLogLevelFromString(String? level, String source) {
    if (level == null) {
      logLevelMap[source] = LogLevel.verbose;
    } else {
      logLevelMap[source] = LogLevel.values.firstWhere(
        (e) => e.name == level.toLowerCase(),
        orElse: () {
          logError(
            '"$level" is not a valid LogLevel. Using default for source "$source".',
            source: "Logging",
          );
          return defaultLogLevel;
        },
      );
    }
  }

  /// Sets the log level for a specific [source].
  static void setLogLevel(LogLevel level, String source) {
    logLevelMap[source] = level;
  }

  /// Logs a message with a specific severity level from a static context.
  static void log(LogLevel level, String message, {required String source}) {
    _logMessage(level, source, message);
  }

  /// Logs an error message from a static context.
  static void logError(String message, {required String source}) =>
      log(LogLevel.error, message, source: source);

  /// Logs a warning message from a static context.
  static void logWarning(String message, {required String source}) =>
      log(LogLevel.warning, message, source: source);

  /// Logs an info message from a static context.
  static void logInfo(String message, {required String source}) =>
      log(LogLevel.info, message, source: source);

  /// Logs a verbose message from a static context.
  static void logVerbose(String message, {required String source}) =>
      log(LogLevel.verbose, message, source: source);

  /// Logs a trace message from a static context.
  static void logTrace(String message, {required String source}) =>
      log(LogLevel.trace, message, source: source);

  /// Logs a pedantic message from a static context.
  static void logPedantic(String message, {required String source}) =>
      log(LogLevel.pedantic, message, source: source);

  ////////////////////////////////////////////////////////////////////////////
  //
  // Internal implementation
  //
  ////////////////////////////////////////////////////////////////////////////

  /// The console logging function installed by user code.
  static void Function(String)? _consoleLogFunction = print;

  /// The optional custom log function installed by user code.
  static void Function(String)? _customLogFunction;

  /// ANSI escape codes for colorizing log output.
  static const _ansiColorMap = {
    LogLevel.error: '\x1B[31m', // Red
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.info: '\x1B[32m', // Green
    LogLevel.verbose: '\x1B[36m', // Cyan
    LogLevel.trace: '\x1B[94m', // Bright Blue
    LogLevel.pedantic: '\x1B[95m', // Bright Magenta
  };
  static const _ansiReset = '\x1B[0m';

  /// Determines if a message with a given [level] and [source] should be logged.
  static bool _shouldLogMessage(String source, LogLevel level) {
    final LogLevel effectiveLevel = logLevelMap[source] ?? defaultLogLevel;
    return level.index <= effectiveLevel.index && level != LogLevel.none;
  }

  /// Formats the log message according to the current [brevity] setting.
  static String _formatMessage(LogLevel level, String source, String message) {
    String formatted;
    switch (brevity) {
      case Brevity.terse:
        formatted = message;
        break;
      case Brevity.normal:
        formatted = "[${level.name}]: $message";
        break;
      case Brevity.detailed:
        formatted = "$source::[${level.name}] $message";
        break;
    }

    if (colorizeOutput && _ansiColorMap.containsKey(level)) {
      return '${_ansiColorMap[level]}$formatted$_ansiReset';
    }
    return formatted;
  }

  /// The core logging function that filters, formats, and outputs the message.
  static void _logMessage(LogLevel level, String source, String message) {
    if (_shouldLogMessage(source, level)) {
      String output = _formatMessage(level, source, message);

      _customLogFunction?.call(output);
      _consoleLogFunction?.call(output);
    }
  }
}
