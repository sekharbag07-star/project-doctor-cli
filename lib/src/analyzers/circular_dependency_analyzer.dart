import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import 'finding.dart';
import 'issue.dart';
import '../core/project_context.dart';

/// Detects cycles in the Dart import dependency graph.
class CircularDependencyAnalyzer implements Analyzer {
  /// Creates a circular dependency analyzer.
  CircularDependencyAnalyzer();

  @override
  String get name => 'CIRCULAR DEPENDENCIES';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final graph = await loadDependencyGraph(context);
    final cycles = graph.cycles();
    final findings = [
      for (var index = 0; index < cycles.length; index++)
        Finding(
          id: 'cycle.$index',
          title: 'Circular dependency detected',
          description: cycles[index].join(' -> '),
          severity: Severity.high,
          category: 'dependencies',
          priority: FindingPriority.high,
          affectedFiles: cycles[index],
          recommendation:
              'Break the cycle by introducing an inward-facing abstraction.',
        ),
    ];
    return findingResult(name, 'Import cycle detection.', findings,
        data: {'Cycles': '${cycles.length}'});
  }
}
