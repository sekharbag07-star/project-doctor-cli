import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import '../core/project_context.dart';

/// Reports the in-memory project dependency graph.
class DependencyGraphAnalyzer implements Analyzer {
  /// Creates a dependency graph analyzer.
  DependencyGraphAnalyzer();

  @override
  String get name => 'DEPENDENCY GRAPH';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final graph = await loadDependencyGraph(context);
    return AnalyzerResult(
      analyzer: name,
      summary: 'Dart files and import edges.',
      data: {
        'Nodes': '${graph.nodes.length}',
        'Edges': '${graph.edges.length}',
        'Cycles': '${graph.cycles().length}',
      },
    );
  }
}
