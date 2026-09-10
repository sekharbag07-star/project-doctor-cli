import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import 'finding.dart';
import 'issue.dart';
import 'source_inventory.dart';
import '../core/project_context.dart';

/// Validates conventional Clean Architecture layer structure.
class ArchitectureAnalyzer implements Analyzer {
  /// Creates an architecture analyzer.
  ArchitectureAnalyzer([Object? legacyScanner]);

  @override
  String get name => 'ARCHITECTURE AUDIT';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final findings = <Finding>[];
    final layerCounts = <String, int>{};
    final inventory = await loadSourceInventory(context);
    for (final path in inventory.contents.keys) {
      final layer = layerOf(path);
      if (layer != null) layerCounts[layer] = (layerCounts[layer] ?? 0) + 1;
    }
    for (final layer in [
      'domain',
      'application',
      'infrastructure',
      'presentation',
    ]) {
      if (!layerCounts.containsKey(layer)) {
        findings.add(Finding(
          id: 'architecture.missing-$layer',
          title: 'Missing $layer layer',
          description:
              'The project does not contain a conventional $layer layer.',
          severity: Severity.medium,
          category: 'architecture',
          priority: FindingPriority.normal,
          affectedFiles: const [],
          recommendation:
              'Create the $layer layer when the project requires it.',
        ));
      }
    }
    return findingResult(
        name, 'Clean Architecture layer validation.', findings, data: {
      for (final entry in layerCounts.entries) entry.key: '${entry.value} files'
    });
  }
}
