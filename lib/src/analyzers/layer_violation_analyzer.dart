import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import 'finding.dart';
import 'issue.dart';
import '../core/project_context.dart';

/// Detects forbidden dependencies between architecture layers.
class LayerViolationAnalyzer implements Analyzer {
  /// Creates a layer violation analyzer.
  LayerViolationAnalyzer();

  @override
  String get name => 'LAYER VIOLATIONS';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final graph = await loadDependencyGraph(context);
    final findings = <Finding>[];
    for (final edge in graph.edges) {
      final source = layerOf(edge.source);
      final target = layerOf(edge.target);
      if (source == null || target == null) continue;
      final forbidden = source == 'domain' && target == 'presentation' ||
          source == 'domain' && target == 'infrastructure' ||
          source == 'application' && target == 'presentation' ||
          source == 'presentation' && target == 'infrastructure';
      if (forbidden) {
        findings.add(Finding(
          id: 'layer.$source-$target',
          title: 'Forbidden layer dependency',
          description: '${edge.source} depends on ${edge.target}.',
          severity: Severity.high,
          category: 'layer',
          priority: FindingPriority.immediate,
          affectedFiles: [edge.source, edge.target],
          recommendation:
              'Reverse the dependency through a stable abstraction.',
        ));
      }
    }
    return findingResult(name, 'Layer dependency direction checks.', findings);
  }
}
