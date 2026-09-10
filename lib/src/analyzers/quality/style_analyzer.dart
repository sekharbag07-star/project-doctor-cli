import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects magic numbers, TODO markers, deprecated annotations, and generated files.
class StyleAnalyzer implements Analyzer {
  /// Creates a style analyzer.
  StyleAnalyzer();
  @override
  String get name => 'STYLE AND DEBT';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      final content = entry.value;
      if (RegExp(r'\bTODO\b|\bFIXME\b').hasMatch(content)) {
        issues.add(_issue(
            'todo.${entry.key}',
            'TODO or FIXME marker',
            IssueType.todo,
            QualityCategory.maintainability,
            Severity.low,
            entry.key,
            'Track the task in an issue or complete it.'));
      }
      if (RegExp(r'@deprecated').hasMatch(content)) {
        issues.add(_issue(
            'deprecated.${entry.key}',
            'Deprecated API declaration',
            IssueType.deprecatedApi,
            QualityCategory.style,
            Severity.low,
            entry.key,
            'Document and migrate callers before removal.'));
      }
      if (RegExp(r'\b(?:if|return|case)\s*\([^\n]*\b(?:0|1|2|100|404)\b')
          .hasMatch(content)) {
        issues.add(_issue(
            'magic.${entry.key}',
            'Magic number detected',
            IssueType.magicNumber,
            QualityCategory.style,
            Severity.low,
            entry.key,
            'Replace unexplained literals with named constants.'));
      }
    }
    return QualitySupport.qualityResult(
        name, 'Style markers and technical debt checks.', issues);
  }

  CodeIssue _issue(
          String id,
          String title,
          IssueType type,
          QualityCategory category,
          Severity severity,
          String file,
          String fix) =>
      CodeIssue(
          id: id,
          title: title,
          description: title,
          severity: severity,
          category: category,
          issueType: type,
          locations: [CodeLocation(file: file)],
          recommendation: Recommendation(
              problem: title,
              reason:
                  'Untracked maintenance signals accumulate technical debt.',
              impact: 'Future changes become less predictable.',
              suggestedFix: fix,
              example: 'Create a named constant or tracked task.',
              priority: 'Low',
              estimatedMinutes: 10));
}
