import 'dart:io';
import 'analyzers/analyzer.dart';
import 'analyzers/analyzer_result.dart';
import 'core/project_context.dart';
import 'core/configuration.dart';
import 'core/logger.dart';
import 'core/command_runner.dart';
import 'report/report_builder.dart';

/// Coordinates analyzers and writes a complete project audit report.
class Doctor {
  /// Creates an audit coordinator with [analyzers] and [reportBuilder].
  Doctor(this.analyzers, this.reportBuilder);

  /// Ordered analyzers executed for each project.
  final List<Analyzer> analyzers;

  /// Report writer used for the final text output.
  final ReportBuilder reportBuilder;

  /// Audits [root] and returns the generated report file.
  Future<File> run(Directory root,
      {Directory? outputDirectory,
      String version = '1.0.0',
      Logger? logger,
      CommandRunner? commandRunner}) async {
    final startedAt = DateTime.now();
    final runner = commandRunner ?? CommandRunner();
    final context = ProjectContext(
        root: root,
        configuration: DoctorConfiguration.load(root),
        commandRunner: runner);
    final effectiveLogger = logger ?? Logger();
    effectiveLogger.info('Auditing ${root.path}');
    final results = await _runAnalyzers(
        context, effectiveLogger, context.configuration.maxConcurrentAnalyzers);
    final reports = outputDirectory ??
        Directory('${root.path}${Platform.pathSeparator}reports');
    await reports.create(recursive: true);
    final stamp = _stamp(startedAt);
    final file = File(
        '${reports.path}${Platform.pathSeparator}project_report_$stamp.txt');
    await reportBuilder.write(
        file: file,
        results: results,
        startedAt: startedAt,
        projectPath: root.absolute.path,
        version: version,
        totalDuration: DateTime.now().difference(startedAt));
    effectiveLogger.info('Report written to ${file.path}');
    return file;
  }

  Future<List<AnalyzerResult>> _runAnalyzers(
      ProjectContext context, Logger logger, int maximumConcurrency) async {
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
      Analyzer analyzer, ProjectContext context, Logger logger) async {
    final started = DateTime.now();
    logger.debug('Starting ${analyzer.name}');
    try {
      final result = await analyzer.analyze(context);
      return AnalyzerResult(
          analyzer: result.analyzer,
          summary: result.summary,
          issues: result.issues,
          data: result.data,
          failed: result.failed,
          duration: DateTime.now().difference(started),
          failureDetails: result.failureDetails,
          startedAt: started,
          finishedAt: DateTime.now());
    } catch (error, stackTrace) {
      logger.warning('${analyzer.name} failed; continuing.');
      return AnalyzerResult(
          analyzer: analyzer.name,
          summary: 'Analyzer failed: $error',
          failed: true,
          duration: DateTime.now().difference(started),
          failureDetails: '$error\n$stackTrace',
          startedAt: started,
          finishedAt: DateTime.now());
    }
  }

  String _stamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
