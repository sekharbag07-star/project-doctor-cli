import 'dart:io';

import 'analyzer.dart';
import 'analyzer_result.dart';
import 'architecture_analysis_support.dart';
import 'finding.dart';
import 'issue.dart';
import '../core/project_context.dart';

/// Validates expected top-level project directories and nesting depth.
class ProjectStructureAnalyzer implements Analyzer {
  /// Creates a project structure analyzer.
  ProjectStructureAnalyzer();

  @override
  String get name => 'PROJECT STRUCTURE';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final findings = <Finding>[];
    final expected = ['lib', 'assets', 'test', 'tool', 'docs', 'example'];
    final existing = <String>{};
    var deepest = 0;
    await for (final entity in context.scanner.scan(context)) {
      final relative = entity.path
          .replaceAll('\\', '/')
          .substring(context.path.replaceAll('\\', '/').length)
          .replaceFirst(RegExp(r'^/'), '');
      final depth = relative.split('/').length;
      if (depth > deepest) deepest = depth;
      if (relative.contains('/')) existing.add(relative.split('/').first);
    }
    for (final directory in expected) {
      if (!existing.contains(directory) &&
          !Directory(context.join(directory)).existsSync()) {
        findings.add(Finding(
          id: 'structure.missing-$directory',
          title: 'Expected directory is missing',
          description: '$directory/ was not found at the project root.',
          severity: Severity.low,
          category: 'structure',
          priority: FindingPriority.low,
          affectedFiles: const [],
          recommendation:
              'Create $directory/ when it is part of the project contract.',
        ));
      }
    }
    if (deepest > 8) {
      findings.add(Finding(
        id: 'structure.deep-nesting',
        title: 'Project nesting is deep',
        description: 'A scanned path is nested $deepest levels deep.',
        severity: Severity.medium,
        category: 'structure',
        priority: FindingPriority.normal,
        affectedFiles: const [],
        recommendation:
            'Flatten deeply nested responsibilities where possible.',
      ));
    }
    return findingResult(
        name, 'Expected project directory and nesting checks.', findings,
        data: {
          'Deepest path': '$deepest',
          'Top-level directories': '${existing.length}'
        });
  }
}
