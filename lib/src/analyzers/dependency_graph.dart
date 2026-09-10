import 'dart:collection';

/// Immutable edge in a project import graph.
class ImportEdge {
  /// Creates an import edge.
  const ImportEdge(
      {required this.source, required this.target, required this.uri});

  /// Importing file path.
  final String source;

  /// Imported project-relative file path or package URI.
  final String target;

  /// Original Dart import URI.
  final String uri;
}

/// In-memory dependency graph shared by architecture analyzers.
class DependencyGraph {
  /// Creates a graph from [nodes] and [edges].
  DependencyGraph(Iterable<String> nodes, Iterable<ImportEdge> edges)
      : nodes = UnmodifiableSetView(nodes.toSet()),
        edges = List.unmodifiable(edges),
        _outgoing = _buildOutgoing(edges);

  /// Graph nodes, represented by normalized file paths.
  final Set<String> nodes;

  /// Import edges.
  final List<ImportEdge> edges;

  final Map<String, List<ImportEdge>> _outgoing;

  /// Returns imports leaving [source].
  Iterable<ImportEdge> outgoing(String source) =>
      _outgoing[source] ?? const <ImportEdge>[];

  /// Finds simple directed cycles in the graph.
  List<List<String>> cycles() {
    final found = <List<String>>[];
    final seenKeys = <String>{};
    for (final node in nodes) {
      _findCycles(node, node, <String>[], <String>{}, found, seenKeys);
    }
    return List.unmodifiable(found);
  }

  void _findCycles(String start, String current, List<String> path,
      Set<String> visiting, List<List<String>> found, Set<String> seenKeys) {
    if (visiting.contains(current)) {
      final cycleStart = path.indexOf(current);
      if (cycleStart >= 0) {
        final cycle = [...path.sublist(cycleStart), current];
        final key = cycle.toSet().toList()..sort();
        if (seenKeys.add(key.join('|'))) found.add(cycle);
      }
      return;
    }
    visiting.add(current);
    path.add(current);
    for (final edge in outgoing(current)) {
      if (nodes.contains(edge.target)) {
        _findCycles(start, edge.target, path, visiting, found, seenKeys);
      }
    }
    path.removeLast();
    visiting.remove(current);
  }

  static Map<String, List<ImportEdge>> _buildOutgoing(
      Iterable<ImportEdge> edges) {
    final map = <String, List<ImportEdge>>{};
    for (final edge in edges) {
      (map[edge.source] ??= []).add(edge);
    }
    return map.map((key, value) => MapEntry(key, List.unmodifiable(value)));
  }
}
