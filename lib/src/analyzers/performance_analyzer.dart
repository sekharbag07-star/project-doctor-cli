import 'analyzer.dart';
import 'analyzer_result.dart';
import 'issue.dart';
import '../core/project_context.dart';
import '../services/file_scanner.dart';

/// Checks source files for performance-related patterns.
class PerformanceAnalyzer implements Analyzer {
  /// Creates a performance analyzer backed by [scanner].
  PerformanceAnalyzer([this.scanner]);

  /// Scanner used to inspect project files.
  final FileScanner? scanner;

  /// Report section title for performance checks.
  @override
  String get name => 'PERFORMANCE AUDIT';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <Issue>[];
    for (final file in context.scanner.dartFiles(context)) {
      final text = file.readAsStringSync();
      if (text.contains('ListView(') && !text.contains('builder:')) {
        issues.add(Issue(
            severity: Severity.medium,
            problem: 'ListView may eagerly build children.',
            reason: 'Eager lists can increase memory use and frame time.',
            files: [file.path],
            recommendedFix:
                'Use ListView.builder for dynamic or large collections.',
            priority: 'Planned'));
      }
    }
    return AnalyzerResult(
        analyzer: name,
        summary: 'Common Flutter rendering and collection checks.',
        issues: issues);
  }
}
