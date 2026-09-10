import 'dart:io';

import '../analyzers/analyzer_metadata.dart';
import 'command_runner.dart';

/// Provides cached values shared by analyzers during one audit.
abstract interface class CacheManager {
  /// Returns the cached value for [key], if present.
  Object? read(String key);

  /// Stores [value] under [key].
  void write(String key, Object value);

  /// Removes all cached values.
  void clear();
}

/// Provides clock readings for deterministic services and tests.
abstract interface class Clock {
  /// Returns the current time.
  DateTime now();
}

/// Provides logging to analyzers and orchestration code.
abstract interface class LoggerService {
  /// Writes a trace message.
  void trace(String message);

  /// Writes an informational message.
  void info(String message);

  /// Writes a warning message.
  void warning(String message);

  /// Writes a debug message.
  void debug(String message);

  /// Writes an error message.
  void error(String message);
}

/// Supplies host environment details for a project.
abstract interface class EnvironmentProvider {
  /// Loads environment information for [root].
  Future<EnvironmentInfo> load(Directory root, CommandRunner runner);
}

/// Supplies Git repository details for a project.
abstract interface class GitProvider {
  /// Loads Git information for [root].
  Future<GitInfo> load(Directory root, CommandRunner runner);
}

/// Supplies SDK details for a project.
abstract interface class SdkProvider {
  /// Loads SDK information for [root].
  Future<SdkInfo> load(Directory root, CommandRunner runner);
}

/// Supplies project-level identity and inventory details.
abstract interface class ProjectInfoProvider {
  /// Loads project information for [root].
  Future<ProjectInfo> load(Directory root);
}

/// Token allowing future cancellation-aware analyzer execution.
abstract interface class CancellationToken {
  /// Whether cancellation has been requested.
  bool get isCancelled;
}

/// Default token for executions that do not support cancellation yet.
class NeverCancelled implements CancellationToken {
  /// Creates a token that is never cancelled.
  const NeverCancelled();

  @override
  bool get isCancelled => false;
}

/// Snapshot of host tools available to the audit.
class EnvironmentInfo {
  /// Creates environment information from tool availability [tools].
  EnvironmentInfo(Map<String, String> tools) : tools = Map.unmodifiable(tools);

  /// Tool names and their detected versions or availability labels.
  final Map<String, String> tools;
}

/// Snapshot of Git state relevant to the audit.
class GitInfo {
  /// Creates Git information from [available] and [branch].
  const GitInfo({this.available = false, this.branch = ''});

  /// Whether Git metadata was available.
  final bool available;

  /// Current branch, when detected.
  final String branch;
}

/// Snapshot of SDK information relevant to the audit.
class SdkInfo {
  /// Creates SDK information from [dartVersion] and [flutterVersion].
  const SdkInfo({this.dartVersion = '', this.flutterVersion = ''});

  /// Detected Dart SDK version.
  final String dartVersion;

  /// Detected Flutter SDK version.
  final String flutterVersion;
}

/// Basic project identity and inventory information.
class ProjectInfo {
  /// Creates project information for [name] and [fileCount].
  const ProjectInfo({required this.name, this.fileCount = 0});

  /// Project directory name.
  final String name;

  /// Number of direct filesystem entries discovered during setup.
  final int fileCount;
}

/// In-memory cache used by the default context factory.
class MemoryCacheManager implements CacheManager {
  final Map<String, Object> _values = {};

  @override
  Object? read(String key) => _values[key];

  @override
  void write(String key, Object value) => _values[key] = value;

  @override
  void clear() => _values.clear();
}

/// Production clock implementation.
class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

/// Detects the ecosystem represented by a project directory.
ProjectType detectProjectType(Directory root) {
  if (File('${root.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
    final contents = File('${root.path}${Platform.pathSeparator}pubspec.yaml')
        .readAsStringSync();
    if (RegExp(r'^\s*flutter:\s*$', multiLine: true).hasMatch(contents) ||
        contents.contains('sdk: flutter')) {
      return ProjectType.flutter;
    }
    return ProjectType.dart;
  }
  return ProjectType.unknown;
}

/// Default provider that checks common host tools.
class DefaultEnvironmentProvider implements EnvironmentProvider {
  /// Creates the default environment provider.
  const DefaultEnvironmentProvider();

  @override
  Future<EnvironmentInfo> load(Directory root, CommandRunner runner) async {
    final tools = <String, String>{};
    for (final tool in ['dart', 'flutter', 'git', 'java', 'adb', 'code']) {
      final result =
          await runner.run(tool, ['--version'], workingDirectory: root.path);
      tools[tool] =
          result.succeeded ? result.stdout.split('\n').first : 'Not available';
    }
    return EnvironmentInfo(tools);
  }
}

/// Default provider that reads the current Git branch.
class DefaultGitProvider implements GitProvider {
  /// Creates the default Git provider.
  const DefaultGitProvider();

  @override
  Future<GitInfo> load(Directory root, CommandRunner runner) async {
    final result = await runner.run('git', ['branch', '--show-current'],
        workingDirectory: root.path);
    return GitInfo(available: result.succeeded, branch: result.stdout.trim());
  }
}

/// Default provider that reads Dart and Flutter SDK versions.
class DefaultSdkProvider implements SdkProvider {
  /// Creates the default SDK provider.
  const DefaultSdkProvider();

  @override
  Future<SdkInfo> load(Directory root, CommandRunner runner) async {
    final dart =
        await runner.run('dart', ['--version'], workingDirectory: root.path);
    final flutter =
        await runner.run('flutter', ['--version'], workingDirectory: root.path);
    return SdkInfo(
      dartVersion: dart.succeeded ? dart.stdout.trim() : '',
      flutterVersion: flutter.succeeded ? flutter.stdout.trim() : '',
    );
  }
}

/// Default provider for basic project identity.
class DefaultProjectInfoProvider implements ProjectInfoProvider {
  /// Creates the default project information provider.
  const DefaultProjectInfoProvider();

  @override
  Future<ProjectInfo> load(Directory root) async => ProjectInfo(
      name: root.uri.pathSegments.where((part) => part.isNotEmpty).last);
}
