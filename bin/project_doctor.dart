// Command-line entrypoint for the Project Doctor audit tool.

import 'dart:io';
import 'package:project_doctor_cli/project_doctor_cli.dart';
import 'package:project_doctor_cli/src/analyzers/dart_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/dependency_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/environment_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/flutter_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/generic_analyzers.dart';
import 'package:project_doctor_cli/src/analyzers/git_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/metrics_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/performance_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/quality_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/security_analyzer.dart';

/// Parses CLI arguments, runs all configured analyzers, and writes a report.
Future<void> main(List<String> arguments) async {
  CliOptions options;
  try {
    options = CliOptions.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln('[ERROR] ${error.message}');
    stderr.writeln('Use --help for usage.');
    exitCode = 2;
    return;
  }
  if (options.showHelp) {
    stdout.write(CliOptions.usage);
    return;
  }
  if (options.showVersion) {
    stdout.writeln('1.0.0');
    return;
  }
  if (!options.projectPath.existsSync()) {
    stderr.writeln(
        '[ERROR] Project directory does not exist: ${options.projectPath.path}');
    exitCode = 2;
    return;
  }
  final registry = AnalyzerRegistry();
  registry.registerFactory(
      _metadata('environment', 'ENVIRONMENT', AnalyzerCategory.environment),
      EnvironmentAnalyzer.new);
  registry.registerFactory(
      _metadata('project-information', 'PROJECT INFORMATION',
          AnalyzerCategory.project),
      ProjectAnalyzer.new);
  registry.registerFactory(
      _metadata('flutter', 'FLUTTER AUDIT', AnalyzerCategory.flutter),
      FlutterAnalyzer.new);
  registry.registerFactory(
      _metadata('dart', 'DART AUDIT', AnalyzerCategory.dart), DartAnalyzer.new);
  registry.registerFactory(
      _metadata('git', 'GIT AUDIT', AnalyzerCategory.git), GitAnalyzer.new);
  registry.registerFactory(
      _metadata(
          'dependencies', 'DEPENDENCY AUDIT', AnalyzerCategory.dependencies),
      DependencyAnalyzer.new);
  registry.registerFactory(
      _metadata(
          'architecture', 'ARCHITECTURE AUDIT', AnalyzerCategory.architecture),
      ArchitectureAnalyzer.new);
  registry.registerFactory(
      _metadata('repository', 'REPOSITORY AUDIT', AnalyzerCategory.repository),
      RepositoryAnalyzer.new);
  registry.registerFactory(
      _metadata('feature', 'FEATURE AUDIT', AnalyzerCategory.feature),
      FeatureAnalyzer.new);
  registry.registerFactory(
      _metadata('imports', 'IMPORT ANALYSIS', AnalyzerCategory.architecture),
      ImportAnalyzer.new);
  registry.registerFactory(
      _metadata('layer-violations', 'LAYER VIOLATIONS',
          AnalyzerCategory.architecture),
      LayerViolationAnalyzer.new);
  registry.registerFactory(
      _metadata('circular-dependencies', 'CIRCULAR DEPENDENCIES',
          AnalyzerCategory.architecture),
      CircularDependencyAnalyzer.new);
  registry.registerFactory(
      _metadata('dependency-graph', 'DEPENDENCY GRAPH',
          AnalyzerCategory.architecture),
      DependencyGraphAnalyzer.new);
  registry.registerFactory(
      _metadata('project-structure', 'PROJECT STRUCTURE',
          AnalyzerCategory.projectStructure),
      ProjectStructureAnalyzer.new);
  registry.registerFactory(
      _metadata('metrics', 'METRICS AUDIT', AnalyzerCategory.metrics),
      MetricsAnalyzer.new);
  registry.registerFactory(
      _metadata('security', 'SECURITY AUDIT', AnalyzerCategory.security),
      SecurityAnalyzer.new);
  registry.registerFactory(
      _metadata(
          'performance', 'PERFORMANCE AUDIT', AnalyzerCategory.performance),
      PerformanceAnalyzer.new);
  registry.registerFactory(
      _metadata('quality', 'QUALITY AUDIT', AnalyzerCategory.quality),
      QualityAnalyzer.new);
  registry.registerFactory(
      _metadata('project-summary', 'PROJECT SUMMARY', AnalyzerCategory.project),
      () =>
          SectionAnalyzer('PROJECT SUMMARY', 'Project health audit summary.'));
  registry.registerFactory(
      _metadata('recommendations', 'RECOMMENDATIONS',
          AnalyzerCategory.recommendations),
      () => SectionAnalyzer('RECOMMENDATIONS',
          'Recommendations are listed from detected issues.'));
  try {
    final file =
        await Doctor.fromRegistry(registry, ReportBuilder(ScoreCalculator()))
            .run(options.projectPath,
                outputDirectory: options.outputDirectory,
                version: '1.0.0',
                logger: Logger(
                    verbose: options.verbose,
                    quiet: options.quiet,
                    noColor: options.noColor));
    if (!options.quiet) stdout.writeln(file.path);
  } catch (error) {
    stderr.writeln('[ERROR] Unable to create report: $error');
    exitCode = 1;
  }
}

AnalyzerMetadata _metadata(
        String id, String displayName, AnalyzerCategory category) =>
    AnalyzerMetadata(
      id: id,
      displayName: displayName,
      description: '$displayName project health checks.',
      category: category,
      supportedProjectTypes: const [ProjectType.dart, ProjectType.flutter],
    );

/// Adds the project metadata section used by the CLI's analyzer list.
class ProjectAnalyzer extends SectionAnalyzer {
  /// Creates the standard project information section.
  ProjectAnalyzer()
      : super('PROJECT INFORMATION', 'Project metadata and root inventory.');
}
