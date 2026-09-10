import 'dart:io';

import '../analyzers/analyzer_metadata.dart';
import '../services/file_scanner.dart';
import 'command_runner.dart';
import 'configuration.dart';
import 'logger.dart';
import 'service_interfaces.dart';

/// Immutable dependency container shared by every analyzer in one audit.
final class ProjectContext {
  /// Creates a context while preserving the original constructor parameters.
  ProjectContext({
    required this.root,
    this.configuration = const DoctorConfiguration(),
    CommandRunner? commandRunner,
    LoggerService? logger,
    ProjectFileScanner? scanner,
    CacheManager? cache,
    EnvironmentInfo? environment,
    GitInfo? git,
    SdkInfo? sdk,
    ProjectInfo? project,
    ProjectType? projectType,
    Directory? workingDirectory,
    Directory? temporaryDirectory,
    Directory? reportDirectory,
    Clock? clock,
    CancellationToken? cancellationToken,
  })  : commandRunner = commandRunner ?? CommandRunner(),
        logger = logger ?? Logger(),
        scanner = scanner ?? FileScanner(),
        cache = cache ?? MemoryCacheManager(),
        environment = environment ?? EnvironmentInfo(const {}),
        git = git ?? const GitInfo(),
        sdk = sdk ?? const SdkInfo(),
        project = project ?? ProjectInfo(name: root.path),
        projectType = projectType ?? detectProjectType(root),
        workingDirectory = workingDirectory ?? root,
        temporaryDirectory = temporaryDirectory ?? Directory.systemTemp,
        reportDirectory = reportDirectory ??
            Directory('${root.path}${Platform.pathSeparator}reports'),
        clock = clock ?? SystemClock(),
        cancellationToken = cancellationToken ?? const NeverCancelled();

  /// Root directory of the project being audited.
  final Directory root;

  /// Effective configuration for the project.
  final DoctorConfiguration configuration;

  /// Process runner shared by command-based analyzers and providers.
  final CommandRunner commandRunner;

  /// Logger shared by the audit.
  final LoggerService logger;

  /// File scanner shared by source-oriented analyzers.
  final ProjectFileScanner scanner;

  /// Run-scoped cache shared by analyzers.
  final CacheManager cache;

  /// Detected host environment information.
  final EnvironmentInfo environment;

  /// Detected Git information.
  final GitInfo git;

  /// Detected SDK information.
  final SdkInfo sdk;

  /// Basic project information.
  final ProjectInfo project;

  /// Detected project ecosystem.
  final ProjectType projectType;

  /// Working directory for this execution.
  final Directory workingDirectory;

  /// Temporary directory available to services.
  final Directory temporaryDirectory;

  /// Directory where the report is written by default.
  final Directory reportDirectory;

  /// Clock used for execution timestamps.
  final Clock clock;

  /// Future-ready cancellation token.
  final CancellationToken cancellationToken;

  /// Returns the platform-specific root path.
  String get path => root.path;

  /// Returns whether [relativePath] exists as a file beneath the root.
  bool exists(String relativePath) => File(join(relativePath)).existsSync();

  /// Resolves [relativePath] against the project root.
  String join(String relativePath) =>
      '${root.path}${Platform.pathSeparator}$relativePath';

  /// Lists direct children of a project-relative directory.
  Iterable<FileSystemEntity> children({String relativePath = ''}) {
    final directory = Directory(join(relativePath));
    if (!directory.existsSync()) return const <FileSystemEntity>[];
    return directory.listSync(followLinks: false);
  }
}
