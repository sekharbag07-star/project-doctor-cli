import 'dart:io';
import 'configuration.dart';
import 'command_runner.dart';

/// Provides filesystem access and configuration for one audit target.
class ProjectContext {
  /// Creates a context rooted at [root].
  const ProjectContext(
      {required this.root,
      this.configuration = const DoctorConfiguration(),
      this.commandRunner});

  /// Root directory of the project being audited.
  final Directory root;

  /// Effective configuration loaded for the project.
  final DoctorConfiguration configuration;

  /// Run-scoped command service shared by all analyzers.
  final CommandRunner? commandRunner;

  /// Returns the platform-specific root path.
  String get path => root.path;

  /// Returns whether [relativePath] exists as a file beneath the root.
  bool exists(String relativePath) => File(_join(relativePath)).existsSync();

  /// Resolves [relativePath] against the project root.
  String join(String relativePath) => _join(relativePath);

  String _join(String relativePath) =>
      '${root.path}${Platform.pathSeparator}$relativePath';

  /// Lists direct children of a project-relative directory.
  Iterable<FileSystemEntity> children({String relativePath = ''}) {
    final directory = Directory(_join(relativePath));
    if (!directory.existsSync()) return const <FileSystemEntity>[];
    return directory.listSync(followLinks: false);
  }
}
