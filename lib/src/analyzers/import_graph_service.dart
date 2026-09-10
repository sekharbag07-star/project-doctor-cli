import '../core/project_context.dart';
import '../services/path_normalizer.dart';
import 'dependency_graph.dart';
import 'source_inventory.dart';

/// Parses Dart imports once and exposes the shared project dependency graph.
class ImportGraphService {
  /// Creates an import graph service.
  ImportGraphService({PathNormalizer? pathNormalizer})
      : pathNormalizer = pathNormalizer ?? const DefaultPathNormalizer();

  /// Normalizer used for graph nodes and edges.
  final PathNormalizer pathNormalizer;

  /// Builds the graph by lazily scanning Dart files once.
  Future<DependencyGraph> build(ProjectContext context) async {
    final inventory = await loadSourceInventory(context);
    final nodes = inventory.contents.keys.toSet();
    final edges = <ImportEdge>[];
    for (final entry in inventory.contents.entries) {
      final content = entry.value;
      for (final match
          in RegExp(r'''(?:import|export|part)\s+['"]([^'"]+)['"]''')
              .allMatches(content)) {
        final uri = match.group(1)!;
        final target = _resolve(entry.key, uri, nodes);
        if (target != null) {
          edges.add(ImportEdge(source: entry.key, target: target, uri: uri));
        }
      }
    }
    return DependencyGraph(nodes, edges);
  }

  String? _resolve(String source, String uri, Set<String> nodes) {
    if (uri.startsWith('dart:')) return null;
    if (uri.startsWith('package:')) {
      final packagePath = uri.substring(uri.indexOf('/') + 1);
      for (final node in nodes) {
        if (node.endsWith(packagePath)) return node;
      }
      return null;
    }
    final sourceDirectory = source.contains('/')
        ? source.substring(0, source.lastIndexOf('/'))
        : '';
    final normalized = pathNormalizer
        .normalize(sourceDirectory.isEmpty ? uri : '$sourceDirectory/$uri');
    return nodes.contains(normalized) ? normalized : null;
  }
}
