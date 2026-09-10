import 'analyzer.dart';
import 'analyzer_result.dart';
import 'issue.dart';
import '../core/project_context.dart';
import '../services/file_scanner.dart';

/// Checks source quality thresholds and maintainability concerns.
class QualityAnalyzer implements Analyzer {
  /// Creates a quality analyzer backed by [scanner].
  QualityAnalyzer([this.scanner]);

  /// Scanner used to inspect source files.
  final FileScanner? scanner;

  /// Report section title for quality checks.
  @override
  String get name => 'QUALITY / TODO / DUPLICATE / DEPRECATED REPORT';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final counts = <String, int>{
      'TODO': 0,
      'FIXME': 0,
      'HACK': 0,
      'XXX': 0,
      'print()': 0,
      'debugPrint()': 0,
      'ignore_for_file': 0,
      'deprecated': 0
    };
    final assets = <String, String>{};
    final issues = <Issue>[];
    for (final file in context.scanner.allFiles(context)) {
      final text = file.readAsStringSync();
      for (final key in counts.keys) {
        counts[key] = counts[key]! + key.allMatches(text).length;
      }
      if (!context.configuration.allowPrint && text.contains('print(')) {
        issues.add(Issue(
            severity: Severity.low,
            problem: 'print() call found.',
            reason:
                'Direct console output is noisy in production and difficult to control.',
            files: [file.path],
            recommendedFix: 'Use an injectable logger with level control.',
            priority: 'Planned'));
      }
      if (!context.configuration.allowDebugPrint &&
          text.contains('debugPrint(')) {
        issues.add(Issue(
            severity: Severity.low,
            problem: 'debugPrint() call found.',
            reason:
                'Debug output should be controlled or removed from release code.',
            files: [file.path],
            recommendedFix:
                'Use a configurable logger or remove the debug statement.',
            priority: 'Planned'));
      }
      final basename = file.path.split(RegExp(r'[/\\]')).last;
      assets[basename] = file.path;
    }
    final duplicates = assets.length - assets.values.toSet().length;
    return AnalyzerResult(
        analyzer: name,
        summary:
            'Maintainability markers, logging, assets, and deprecated API indicators.',
        issues: issues,
        data: {
          for (final entry in counts.entries) entry.key: '${entry.value}',
          'Duplicate file names': '$duplicates',
          'Asset files': '${assets.length}'
        });
  }
}
