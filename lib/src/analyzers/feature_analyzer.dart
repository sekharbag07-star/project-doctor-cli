import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import 'finding.dart';
import 'issue.dart';
import 'source_inventory.dart';
import '../core/project_context.dart';

/// Discovers feature boundaries and reports oversized features.
class FeatureAnalyzer implements Analyzer {
  /// Creates a feature analyzer.
  FeatureAnalyzer([Object? legacyScanner]);

  @override
  String get name => 'FEATURE AUDIT';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final counts = <String, int>{};
    final filesByFeature = <String, List<String>>{};
    final inventory = await loadSourceInventory(context);
    for (final path in inventory.contents.keys) {
      final feature = featureOf(path);
      if (feature != null) {
        counts[feature] = (counts[feature] ?? 0) + 1;
        (filesByFeature[feature] ??= []).add(path);
      }
    }
    final findings = <Finding>[];
    for (final entry in counts.entries.where((entry) => entry.value > 100)) {
      findings.add(Finding(
        id: 'feature.too-large-${entry.key}',
        title: 'Feature is oversized',
        description: 'Feature ${entry.key} contains ${entry.value} Dart files.',
        severity: Severity.medium,
        category: 'feature',
        priority: FindingPriority.normal,
        affectedFiles: filesByFeature[entry.key]!,
        recommendation: 'Split the feature into smaller isolated sub-features.',
      ));
    }
    return findingResult(
        name, 'Feature discovery and boundary checks.', findings,
        data: {
          'Features': '${counts.length}',
          ...{
            for (final entry in counts.entries)
              entry.key: '${entry.value} files'
          }
        });
  }
}
