// Command-line entrypoint for the Project Doctor audit tool.

import 'dart:io';
import 'package:project_doctor_cli/project_doctor_cli.dart';
import 'package:project_doctor_cli/src/analyzers/architecture_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/dart_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/dependency_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/environment_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/feature_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/flutter_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/generic_analyzers.dart';
import 'package:project_doctor_cli/src/analyzers/git_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/metrics_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/performance_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/quality_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/repository_analyzer.dart';
import 'package:project_doctor_cli/src/analyzers/security_analyzer.dart';
import 'package:project_doctor_cli/src/services/file_scanner.dart';

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
  final runner = CommandRunner();
  final scanner = FileScanner();
  final analyzers = <Analyzer>[
    EnvironmentAnalyzer(runner),
    ProjectAnalyzer(),
    FlutterAnalyzer(runner),
    DartAnalyzer(runner),
    GitAnalyzer(runner),
    DependencyAnalyzer(runner),
    ArchitectureAnalyzer(scanner),
    RepositoryAnalyzer(scanner),
    FeatureAnalyzer(scanner),
    MetricsAnalyzer(scanner),
    SecurityAnalyzer(scanner),
    PerformanceAnalyzer(scanner),
    QualityAnalyzer(scanner),
    SectionAnalyzer('PROJECT SUMMARY', 'Project health audit summary.'),
    SectionAnalyzer(
        'RECOMMENDATIONS', 'Recommendations are listed from detected issues.'),
  ];
  try {
    final file = await Doctor(analyzers, ReportBuilder(ScoreCalculator())).run(
        options.projectPath,
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

/// Adds the project metadata section used by the CLI's analyzer list.
class ProjectAnalyzer extends SectionAnalyzer {
  /// Creates the standard project information section.
  ProjectAnalyzer()
      : super('PROJECT INFORMATION', 'Project metadata and root inventory.');
}
