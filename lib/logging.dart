// This logging framework handles logging with different severity levels
// and tracks the source of each log message from the class that emitted the
// log message.
// The frame also allow for dynamic runtime filtering of log events by level
// and by source.
// Additionally it supports redirecting the log messages to other sources besides
// the console, e.g. using the XTerm widget

/// The log levels, in priority order
/// e.g. if logLevel is set to "warning",  only error and warnings will be shown
enum LogLevel {
  /// Don't log any errors
  none,

  /// Only log errors
  error,

  /// Log warnings and other levels above this level
  warning,

  /// Log info and other levels above this level
  info,

  /// Log verbose and other levels above this level
  verbose,

  /// Log trace and other levels above this level
  trace,

  /// Log pedantic and other levels above this level
  pedantic,
}

/// How detailed to make log messages
enum Brevity {
  /// Displays just the message
  terse,

  /// Displays the message and the severity
  normal,

  /// Displays the message, the severity and the source
  detailed,
}

/// Add this mixin to any classes that you want to output log messages from
mixin class LoggableClass {
  /// Log an message with severity level Error
  void logError(String message) {
    Logging.logError(message, source: runtimeType.toString());
  }

  /// Log an message with severity level Warning
  void logWarning(String message) {
    Logging.logWarning(message, source: runtimeType.toString());
  }

  /// Log an message with severity level Info
  void logInfo(String message) {
    Logging.logInfo(message, source: runtimeType.toString());
  }

  /// Log an message with severity level Verbose
  void logVerbose(String message) {
    Logging.logVerbose(message, source: runtimeType.toString());
  }

  /// Log an message with severity level Trace
  void logTrace(String message) {
    Logging.logTrace(message, source: runtimeType.toString());
  }

  /// Log an message with severity level Pedantic
  void logPedantic(String message) {
    Logging.logPedantic(message, source: runtimeType.toString());
  }
}

/// Use this class to configure logging.
/// There's no need to instantiate it, as it's not a singleton and it
/// only contains static fields and methods
///
/// It also possible to directly call the logging methods on this class
/// when emitting log messages that are not part of a class, e.g.:
///
/// Logging.logInfo("Some important message",source:"mainLoop");
///
/// but for logging from classes it is preferred to use the LoggableClass mixin,
/// which provides a less verbose way of creating log statements
///
/// class MyClass with LoggableClass {
///    void onSomethingBad() {
///       // Preferred way to log:
///       logError("Oh Noes! Something Bad Happened!");
///
///       // Works, but requires a lot more typing
///       Logging.logError("Oh Noes! Something Bad Happened!",source:"MyClass");
///    }
/// }
///
///
class Logging {

  // If the map contains an entry for a source, then the stored LogLevel is
  // used as a filter
  static Map<String,LogLevel> logLevelMap={};

  /// The current logger brevity setting
  static Brevity brevity = Brevity.normal;

  // Whether or not to show log that haven't specified their filter level
  static bool displayUnfilteredLogs = true;

  /// Install a console logging function, e.g.  use to the 'print' function
  /// Pass in a void function [func] that accepts a string like so:
  ///   Logging.setConsoleLogFunction((String message) {
  ///     print(message);
  ///   });
  static void setConsoleLogFunction(void Function(String arg) func) {
    _consoleLogFunction = func;
  }

  /// Install a custom logging function, e.g. for redirecting the log to
  /// a widget. Pass in a void function [func] that accepts a string
  static void setCustomLogFunction(void Function(String arg) func) {
    _customLogFunction = func;
  }

  /// Set the log level for a source from a string. Useful when the log level
  /// for an application is stored in a configuration file.
  /// Takes a string parameter [level] to set the level
  /// A level of null is interpreted as verbose
  static void setLogLevelFromString(String? level,String source) {
    if (level == null) {
      logLevelMap[source] = LogLevel.verbose;
    } else {
      logLevelMap[source] = LogLevel.values.firstWhere(
            (e) => e.toString() == 'LogLevel.$level',
      );
    }
  }

  // Set the log level for a source
  static void setLogLevel(LogLevel level,String source) {
      logLevelMap[source] = level;
  }

  /// Log a message with severity level of Error
  /// For logging messages from classes, it's preferred for to invoke this via
  /// the Loggable mixin which automatically sets the source
  ///
  /// This interface is primarily for invoking logs from static methods and
  /// from outside of classes
  ///
  /// Takes two parameters, the [message] and the [source]
  static void logError(String message, {required String source}) {
    _logMessage(LogLevel.error, source, message);
  }

  /// Log a message with severity level of Warning
  /// See LogError for preferred usage pattern
  /// Takes two parameters, the [message] and the [source]
  static void logWarning(String message, {required String source}) {
    _logMessage(LogLevel.warning, source, message);
  }

  /// Log a message with severity level of Info
  /// See LogError for preferred usage pattern
  /// Takes two parameters, the [message] and the [source]
  static void logInfo(String message, {required String source}) {
    _logMessage(LogLevel.info, source, message);
  }

  /// Log a message with severity level of Verbose
  /// See LogError for preferred usage pattern
  /// Takes two parameters, the [message] and the [source]
  static void logVerbose(String message, {required String source}) {
    _logMessage(LogLevel.verbose, source, message);
  }

  /// Log a message with severity level of Trace
  /// See LogError for preferred usage pattern
  /// Takes two parameters, the [message] and the [source]
  static void logTrace(String message, {required String source}) {
    _logMessage(LogLevel.trace, source, message);
  }

  /// Log a message with severity level of Pedantic
  /// See LogError for preferred usage pattern
  /// Takes two parameters, the [message] and the [source]
  static void logPedantic(String message, {required String source}) {
    _logMessage(LogLevel.pedantic, source, message);
  }

  ////////////////////////////////////////////////////////////////////////////
  //
  // Internal implementation
  //
  ////////////////////////////////////////////////////////////////////////////
  /// Console logging function installed by user code
  static void Function(String)? _consoleLogFunction;

  /// Optional custom log function installed by user code
  static void Function(String)? _customLogFunction;

  /// Helper function to determine if a log message should be emitted
  static bool _shouldLogMessage(String source, LogLevel level) {
    LogLevel? configuredLevel = logLevelMap[source];

    if (configuredLevel != null) {
      return (configuredLevel.index >= level.index);
    } else {
      return displayUnfilteredLogs;
    }
  }

  static String _formatMessage(LogLevel level, String source, String message) {
    switch (brevity) {
      case Brevity.terse:
        return message;
      case Brevity.normal:
        return "[${level.name}]: $message";
      case Brevity.detailed:
        return "$source::[${level.name}] $message";
    }
  }

  /// Emit a formatted log message, if it passes the filter test
  static void _logMessage(LogLevel level, String source, String message) {
    if (_shouldLogMessage(source, level)) {
      String output = _formatMessage(level, source, message);

      if (_customLogFunction != null) {
        _customLogFunction!(output);
      }

      if (_consoleLogFunction != null) {
        _consoleLogFunction!(output);
      }
    }
  }
}
