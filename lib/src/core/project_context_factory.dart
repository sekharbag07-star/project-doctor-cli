import 'dart:io';

import '../services/file_scanner.dart';
import 'command_runner.dart';
import 'configuration.dart';
import 'logger.dart';
import 'project_context.dart';
import 'service_interfaces.dart';

/// Builds the complete dependency container for one audit execution.
class ProjectContextFactory {
  /// Creates a factory with replaceable providers for deterministic tests.
  const ProjectContextFactory({
    this.environmentProvider = const DefaultEnvironmentProvider(),
    this.gitProvider = const DefaultGitProvider(),
    this.sdkProvider = const DefaultSdkProvider(),
    this.projectInfoProvider = const DefaultProjectInfoProvider(),
  });

  /// Provider for host environment details.
  final EnvironmentProvider environmentProvider;

  /// Provider for Git details.
  final GitProvider gitProvider;

  /// Provider for SDK details.
  final SdkProvider sdkProvider;

  /// Provider for project details.
  final ProjectInfoProvider projectInfoProvider;

  /// Creates one fully initialized context for [root].
  Future<ProjectContext> create(Directory root,
      {LoggerService? logger,
      CommandRunner? commandRunner,
      ProjectFileScanner? scanner,
      CacheManager? cache,
      Clock? clock,
      CancellationToken? cancellationToken,
      Directory? temporaryDirectory,
      Directory? reportDirectory}) async {
    final runner = commandRunner ?? CommandRunner();
    final configuration = DoctorConfiguration.load(root);
    return ProjectContext(
      root: root,
      configuration: configuration,
      commandRunner: runner,
      logger: logger ?? Logger(),
      scanner: scanner ?? FileScanner(),
      cache: cache,
      environment: await environmentProvider.load(root, runner),
      git: await gitProvider.load(root, runner),
      sdk: await sdkProvider.load(root, runner),
      project: await projectInfoProvider.load(root),
      projectType: detectProjectType(root),
      workingDirectory: root,
      temporaryDirectory: temporaryDirectory,
      reportDirectory: reportDirectory,
      clock: clock,
      cancellationToken: cancellationToken,
    );
  }
}
