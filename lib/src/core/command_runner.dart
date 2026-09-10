import 'dart:convert';
import 'dart:io';

/// Captures the result of an external process invocation.
class CommandResult {
  /// Creates a process result from its exit code and output streams.
  const CommandResult({
    this.command = '',
    this.arguments = const [],
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.duration = Duration.zero,
    this.timedOut = false,
  });

  /// Executable that was invoked.
  final String command;

  /// Arguments passed to [command].
  final List<String> arguments;

  /// Process exit code returned by the operating system.
  final int exitCode;

  /// Trimmed standard output.
  final String stdout;

  /// Trimmed standard error output.
  final String stderr;

  /// Time spent executing the command.
  final Duration duration;

  /// Whether the process was terminated because it exceeded its timeout.
  final bool timedOut;

  /// Whether the process completed successfully.
  bool get succeeded => exitCode == 0;

  /// Alias for [succeeded] used by command-oriented callers.
  bool get success => succeeded;
}

/// Runs external commands from a project directory.
class CommandRunner {
  final Map<String, Future<CommandResult>> _cache = {};

  /// Runs [executable] with [arguments] in [workingDirectory].
  ///
  /// Results are cached for the lifetime of this runner unless [cache] is
  /// false. The optional [environment] is passed to the child process.
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    Duration timeout = const Duration(seconds: 30),
    Map<String, String>? environment,
    bool cache = true,
  }) {
    final key = _cacheKey(
        executable, arguments, workingDirectory, timeout, environment);
    if (cache) {
      final cached = _cache[key];
      if (cached != null) return cached;
    }
    final result = _execute(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      timeout: timeout,
      environment: environment,
    );
    if (cache) _cache[key] = result;
    return result;
  }

  /// Clears all command results cached by this runner.
  void clearCache() => _cache.clear();

  Future<CommandResult> _execute(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required Duration timeout,
    Map<String, String>? environment,
  }) async {
    final started = DateTime.now();
    Process? process;
    var timedOut = false;
    try {
      process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: Platform.isWindows,
      );
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
        timedOut = true;
        process?.kill();
        return 124;
      });
      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;
      return CommandResult(
        command: executable,
        arguments: List.unmodifiable(arguments),
        exitCode: exitCode,
        stdout: stdout.trim(),
        stderr:
            timedOut ? '${stderr.trim()}\nCommand timed out.' : stderr.trim(),
        duration: DateTime.now().difference(started),
        timedOut: timedOut,
      );
    } catch (error) {
      process?.kill();
      return CommandResult(
        command: executable,
        arguments: List.unmodifiable(arguments),
        exitCode: 1,
        stdout: '',
        stderr: '$error',
        duration: DateTime.now().difference(started),
        timedOut: timedOut,
      );
    }
  }

  String _cacheKey(
      String executable,
      List<String> arguments,
      String workingDirectory,
      Duration timeout,
      Map<String, String>? environment) {
    final environmentKey = environment == null
        ? ''
        : (environment.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
            .map((entry) => '${entry.key}=${entry.value}')
            .join(';');
    return '$executable\u0000${arguments.join('\u0000')}\u0000$workingDirectory\u0000${timeout.inMicroseconds}\u0000$environmentKey';
  }
}
