import 'dart:io';
import 'service_interfaces.dart';

/// Categories supported by the project doctor's logger.
enum LogLevel {
  /// Highly detailed diagnostic information.
  trace,

  /// Normal progress information.
  info,

  /// Recoverable problem information.
  warning,

  /// An operation or audit error.
  error,

  /// Verbose diagnostic information.
  debug
}

/// Writes consistently formatted messages to the terminal.
class Logger implements LoggerService {
  /// Creates a logger with optional verbosity and quiet-mode controls.
  Logger({this.verbose = false, this.quiet = false, this.noColor = false});

  /// Whether debug messages should be emitted.
  final bool verbose;

  /// Whether informational and warning messages should be suppressed.
  final bool quiet;

  /// Whether ANSI color sequences should be omitted.
  final bool noColor;

  void _write(LogLevel level, String message) {
    if (quiet && level != LogLevel.error) return;
    if (level == LogLevel.debug && !verbose) return;
    if (level == LogLevel.trace && !verbose) return;
    final label = level.name.toUpperCase();
    final output =
        noColor ? '[$label] $message' : _colored(level, label, message);
    (level == LogLevel.warning || level == LogLevel.error ? stderr : stdout)
        .writeln(output);
  }

  String _colored(LogLevel level, String label, String message) {
    final color = switch (level) {
      LogLevel.trace => '\x1B[90m',
      LogLevel.debug => '\x1B[36m',
      LogLevel.info => '\x1B[32m',
      LogLevel.warning => '\x1B[33m',
      LogLevel.error => '\x1B[31m',
    };
    return '$color[$label]\x1B[0m $message';
  }

  /// Writes a trace message when verbose logging is enabled.
  @override
  void trace(String message) => _write(LogLevel.trace, message);

  /// Writes an informational message to standard output.
  @override
  void info(String message) {
    _write(LogLevel.info, message);
  }

  /// Writes a warning message to standard error.
  @override
  void warning(String message) {
    _write(LogLevel.warning, message);
  }

  /// Writes an error message to standard error.
  @override
  void error(String message) => _write(LogLevel.error, message);

  /// Writes a debug message when verbose logging is enabled.
  @override
  void debug(String message) {
    _write(LogLevel.debug, message);
  }
}
