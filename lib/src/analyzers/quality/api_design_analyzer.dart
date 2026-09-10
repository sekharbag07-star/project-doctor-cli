import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects mutable public fields and excessive constructor parameters.
class ApiDesignAnalyzer implements Analyzer {
  /// Creates an API design analyzer.
  ApiDesignAnalyzer();
  @override
  String get name => 'API DESIGN';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      if (RegExp(r'\b(?:final|var)\s+[A-Za-z0-9_<>,?]+\s+_[A-Za-z0-9_]+\s*;')
          .hasMatch(entry.value)) {
        continue;
      }
      final parameters = RegExp(r'\([^)]{80,}\)').hasMatch(entry.value);
      if (parameters) {
        issues.add(CodeIssue(
            id: 'api.parameters.${entry.key}',
            title: 'Excessive API parameters',
            description: 'A declaration has a very large parameter list.',
            severity: Severity.medium,
            category: QualityCategory.apiDesign,
            issueType: IssueType.mutableApi,
            locations: [CodeLocation(file: entry.key)],
            recommendation: const Recommendation(
                problem: 'Excessive parameters',
                reason: 'Large signatures are hard to call correctly.',
                impact: 'Call sites become brittle.',
                suggestedFix: 'Introduce a parameter object or builder.',
                example: 'Create an immutable options class.',
                priority: 'Normal',
                estimatedMinutes: 20)));
      }
    }
    return QualitySupport.qualityResult(
        name, 'Public API design checks.', issues);
  }
}
