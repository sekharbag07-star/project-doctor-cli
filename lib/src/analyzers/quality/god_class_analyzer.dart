import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects classes with excessive size and responsibility signals.
class GodClassAnalyzer implements Analyzer {
  /// Creates a god-class analyzer.
  GodClassAnalyzer();
  @override
  String get name => 'GOD CLASSES';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      final classes = RegExp(r'\bclass\s+\w+').allMatches(entry.value).length;
      if (classes > 3 || entry.value.split('\n').length > 500) {
        issues.add(CodeIssue(
          id: 'class.god.${entry.key}',
          title: 'Potential god class',
          description: 'A file contains many classes or excessive source size.',
          severity: Severity.medium,
          category: QualityCategory.maintainability,
          issueType: IssueType.godClass,
          locations: [CodeLocation(file: entry.key)],
          recommendation: const Recommendation(
              problem: 'God class',
              reason: 'Too many responsibilities increase coupling.',
              impact: 'Changes become risky and slow.',
              suggestedFix: 'Split classes by responsibility.',
              example: 'Extract domain services and data mappers.',
              priority: 'Normal',
              estimatedMinutes: 60),
        ));
      }
    }
    return QualitySupport.qualityResult(
        name, 'Class size and responsibility checks.', issues);
  }
}
