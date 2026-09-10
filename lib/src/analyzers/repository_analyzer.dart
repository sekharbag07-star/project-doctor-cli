import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import 'finding.dart';
import 'issue.dart';
import 'source_inventory.dart';
import '../core/project_context.dart';

/// Validates repository abstractions and implementations.
class RepositoryAnalyzer implements Analyzer {
  /// Creates a repository analyzer.
  RepositoryAnalyzer([Object? legacyScanner]);

  @override
  String get name => 'REPOSITORY AUDIT';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final interfaces = <String>[];
    final implementations = <String>[];
    final inventory = await loadSourceInventory(context);
    for (final entry in inventory.contents.entries) {
      final path = entry.key;
      final content = entry.value;
      if (RegExp(r'abstract\s+(?:interface\s+)?class\s+\w*Repository')
          .hasMatch(content)) {
        interfaces.add(path);
      }
      if (RegExp(r'class\s+\w*Repository\w*\s+implements\s+')
          .hasMatch(content)) {
        implementations.add(path);
      }
    }
    final findings = <Finding>[];
    if (implementations.isNotEmpty && interfaces.isEmpty) {
      findings.add(Finding(
        id: 'repository.missing-abstraction',
        title: 'Repository implementation lacks abstraction',
        description:
            'Repository implementations were found without repository interfaces.',
        severity: Severity.medium,
        category: 'repository',
        priority: FindingPriority.high,
        affectedFiles: implementations,
        recommendation: 'Define repository interfaces in the domain layer.',
      ));
    }
    return findingResult(
        name, 'Repository abstraction and placement checks.', findings,
        data: {
          'Interfaces': '${interfaces.length}',
          'Implementations': '${implementations.length}'
        });
  }
}
