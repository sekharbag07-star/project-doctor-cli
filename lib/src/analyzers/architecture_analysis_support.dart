import '../core/project_context.dart';
import 'analyzer_result.dart';
import 'dependency_graph.dart';
import 'finding.dart';
import 'import_graph_service.dart';

const _graphCacheKey = 'phase5.dependencyGraph';

/// Loads the shared dependency graph once per audit context.
Future<DependencyGraph> loadDependencyGraph(ProjectContext context) async {
  final cached = context.cache.read(_graphCacheKey);
  if (cached is Future<DependencyGraph>) return cached;
  final future = ImportGraphService().build(context);
  context.cache.write(_graphCacheKey, future);
  return future;
}

/// Converts structured findings to the existing analyzer result contract.
AnalyzerResult findingResult(
    String analyzer, String summary, Iterable<Finding> findings,
    {Map<String, String> data = const {}}) {
  final list = findings.toList(growable: false);
  return AnalyzerResult(
    analyzer: analyzer,
    summary: summary,
    issues: list.map((finding) => finding.toIssue()).toList(growable: false),
    data: data,
  );
}

/// Returns the conventional architecture layer represented by [path].
String? layerOf(String path) {
  final segments = path.split('/');
  for (final layer in [
    'domain',
    'application',
    'infrastructure',
    'presentation',
    'shared',
  ]) {
    if (segments.contains(layer)) return layer;
  }
  return null;
}

/// Returns a feature name when [path] is inside a conventional feature root.
String? featureOf(String path) {
  final segments = path.split('/');
  final index = segments.indexOf('features');
  if (index >= 0 && index + 1 < segments.length) return segments[index + 1];
  return null;
}
