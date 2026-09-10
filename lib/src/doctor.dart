import 'dart:io';
import 'analyzers/analyzer.dart';
import 'analyzers/analyzer_result.dart';
import 'analyzers/analyzer_registry.dart';
import 'core/project_context.dart';
import 'core/command_runner.dart';
import 'core/logger.dart';
import 'report/report_builder.dart';
import 'core/project_context_factory.dart';
import 'core/service_interfaces.dart';

/// Coordinates analyzers and writes a complete project audit report.
class Doctor {
  /// Creates an audit coordinator with [analyzers] and [reportBuilder].
  Doctor(this.analyzers, this.reportBuilder,
      {ProjectContextFactory? contextFactory})
      : contextFactory = contextFactory ?? const ProjectContextFactory();

  /// Creates an audit coordinator from lazily registered analyzers.
  Doctor.fromRegistry(AnalyzerRegistry registry, this.reportBuilder,
      {ProjectContextFactory? contextFactory})
      : analyzers = registry.analyzers.toList(growable: false),
        contextFactory = contextFactory ?? const ProjectContextFactory();

  /// Ordered analyzers executed for each project.
  final List<Analyzer> analyzers;

  /// Report writer used for the final text output.
  final ReportBuilder reportBuilder;

  /// Factory used to create the shared execution context.
  final ProjectContextFactory contextFactory;

  /// Audits [root] and returns the generated report file.
  Future<File> run(Directory root,
      {Directory? outputDirectory,
      String version = '1.0.0',
      Logger? logger,
      CommandRunner? commandRunner}) async {
    final context = await contextFactory.create(root,
        logger: logger,
        commandRunner: commandRunner,
        reportDirectory: outputDirectory);
    final startedAt = context.clock.now();
    final effectiveLogger = context.logger;
    effectiveLogger.info('Auditing ${root.path}');
    final results = await _runAnalyzers(
        context, effectiveLogger, context.configuration.maxConcurrentAnalyzers);
    final file = await reportBuilder.writeToDirectory(
        directory: context.reportDirectory,
        results: results,
        startedAt: startedAt,
        projectPath: root.absolute.path,
        version: version,
        totalDuration: DateTime.now().difference(startedAt));
    effectiveLogger.info('Report written to ${file.path}');
    return file;
  }

  Future<List<AnalyzerResult>> _runAnalyzers(ProjectContext context,
      LoggerService logger, int maximumConcurrency) async {
    if (analyzers.isEmpty) return const [];
    final results = List<AnalyzerResult?>.filled(analyzers.length, null);
    var nextIndex = 0;
    final workerCount = maximumConcurrency.clamp(1, analyzers.length);

    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= analyzers.length) return;
        results[index] = await _runAnalyzer(analyzers[index], context, logger);
      }
    }

    await Future.wait(List.generate(workerCount, (_) => worker()));
    return results.cast<AnalyzerResult>();
  }

  Future<AnalyzerResult> _runAnalyzer(
      Analyzer analyzer, ProjectContext context, LoggerService logger) async {
    final started = context.clock.now();
    logger.debug('Starting ${analyzer.name}');
    try {
      final result = await analyzer.analyze(context);
      return AnalyzerResult(
          analyzer: result.analyzer,
          summary: result.summary,
          issues: result.issues,
          data: result.data,
          failed: result.failed,
          duration: context.clock.now().difference(started),
          failureDetails: result.failureDetails,
          startedAt: started,
          finishedAt: context.clock.now());
    } catch (error, stackTrace) {
      logger.warning('${analyzer.name} failed; continuing.');
      return AnalyzerResult(
          analyzer: analyzer.name,
          summary: 'Analyzer failed: $error',
          failed: true,
          duration: context.clock.now().difference(started),
          failureDetails: '$error\n$stackTrace',
          startedAt: started,
          finishedAt: context.clock.now());
    }
  }
}
