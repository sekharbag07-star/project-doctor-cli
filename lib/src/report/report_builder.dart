import 'dart:io';
import '../analyzers/analyzer_result.dart';
import '../analyzers/issue.dart';
import 'score_calculator.dart';

/// Serializes analyzer results into the human-readable report format.
class ReportBuilder {
  /// Creates a report builder using [scoreCalculator].
  ReportBuilder(this.scoreCalculator);

  /// Calculator used to produce the final health score.
  final ScoreCalculator scoreCalculator;

  /// Writes [results] and execution metadata to [file].
  Future<void> write(
      {required File file,
      required List<AnalyzerResult> results,
      required DateTime startedAt,
      String version = '1.0.0',
      String projectPath = '',
      Duration totalDuration = Duration.zero}) async {
    final sink = file.openWrite();
    try {
      sink.writeln('PROJECT DOCTOR REPORT');
      sink.writeln('Tool version: $version');
      sink.writeln('Execution timestamp: ${startedAt.toIso8601String()}');
      sink.writeln('Project path: $projectPath');
      sink.writeln('Total execution time: ${totalDuration.inMilliseconds} ms');
      sink.writeln('='.padRight(80, '='));
      sink.writeln();
      sink.writeln('TABLE OF CONTENTS');
      for (var index = 0; index < results.length; index++) {
        sink.writeln('${index + 1}. ${results[index].analyzer}');
      }
      sink.writeln();
      sink.writeln('SUMMARY');
      sink.writeln('Analyzers: ${results.length}');
      sink.writeln(
          'Failures: ${results.where((result) => result.failed).length}');
      sink.writeln(
          'Issues: ${results.fold<int>(0, (total, result) => total + result.issues.length)}');
      sink.writeln();
      for (final result in results) {
        _writeSection(sink, result);
      }
      final score = scoreCalculator.calculate(results);
      sink.writeln('FINAL HEALTH SCORE');
      sink.writeln('Overall: $score/100');
      sink.writeln();
      sink.writeln('RECOMMENDATIONS');
      for (final issue in results
          .expand((result) => result.issues)
          .where((issue) => issue.severity.index <= Severity.high.index)) {
        sink.writeln('- [${issue.priority}] ${issue.recommendedFix}');
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  void _writeSection(IOSink sink, AnalyzerResult result) {
    sink.writeln(result.analyzer);
    sink.writeln('-'.padRight(result.analyzer.length, '-'));
    sink.writeln(result.summary);
    sink.writeln('Execution time: ${result.duration.inMilliseconds} ms');
    for (final entry in result.data.entries) {
      sink.writeln('${entry.key}: ${entry.value}');
    }
    if (result.failed) {
      sink.writeln('Analyzer failed; the remaining audit continued.');
    }
    if (result.failureDetails != null) {
      sink.writeln('Failure details:\n${result.failureDetails}');
    }
    for (final issue in result.issues) {
      sink.writeln();
      sink.writeln(issue.severityLabel);
      sink.writeln('Problem: ${issue.problem}');
      sink.writeln('Why it matters: ${issue.reason}');
      sink.writeln(
          'Affected files: ${issue.files.isEmpty ? 'None reported' : issue.files.join(', ')}');
      sink.writeln('Recommended fix: ${issue.recommendedFix}');
      sink.writeln('Priority: ${issue.priority}');
    }
    sink.writeln();
  }
}
