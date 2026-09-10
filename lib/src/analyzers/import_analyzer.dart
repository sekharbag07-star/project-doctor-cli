import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import 'finding.dart';
import 'issue.dart';
import '../core/project_context.dart';

/// Reports parsed Dart import relationships and architectural import smells.
class ImportAnalyzer implements Analyzer {
  /// Creates an import analyzer.
  ImportAnalyzer();

  @override
  String get name => 'IMPORT ANALYSIS';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final graph = await loadDependencyGraph(context);
    final findings = <Finding>[];
    for (final edge in graph.edges) {
      final sourceLayer = layerOf(edge.source);
      final targetLayer = layerOf(edge.target);
      if (sourceLayer == 'presentation' && targetLayer == 'infrastructure' ||
          sourceLayer == 'domain' && targetLayer == 'presentation' ||
          sourceLayer == 'application' && targetLayer == 'presentation') {
        findings.add(Finding(
          id: 'import.layer-${edge.source}-${edge.target}',
          title: 'Layer import boundary crossed',
          description: '${edge.source} imports ${edge.target}.',
          severity: Severity.high,
          category: 'imports',
          priority: FindingPriority.high,
          affectedFiles: [edge.source, edge.target],
          recommendation:
              'Depend on inward-facing abstractions instead of this layer.',
        ));
      }
    }
    return findingResult(name, 'Dart import graph analysis.', findings, data: {
      'Nodes': '${graph.nodes.length}',
      'Imports': '${graph.edges.length}'
    });
  }
}
