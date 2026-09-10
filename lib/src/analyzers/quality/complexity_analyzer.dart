import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects excessive branching, nesting, and method size.
class ComplexityAnalyzer implements Analyzer {
  /// Creates a complexity analyzer.
  ComplexityAnalyzer();
  @override
  String get name => 'CODE COMPLEXITY';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      final metric = QualitySupport.metrics(entry.value, 0);
      if (metric.cyclomaticComplexity > 15 || metric.cognitiveComplexity > 25) {
        issues.add(CodeIssue(
          id: 'complexity.${entry.key}',
          title: 'High code complexity',
          description: 'Estimated complexity exceeds maintainable thresholds.',
          severity: Severity.high,
          category: QualityCategory.complexity,
          issueType: IssueType.deepNesting,
          locations: [CodeLocation(file: entry.key)],
          recommendation: const Recommendation(
              problem: 'Complex code',
              reason: 'Complex branches are difficult to test.',
              impact: 'Higher defect risk.',
              suggestedFix: 'Split branching logic into focused functions.',
              example: 'Extract a strategy or helper.',
              priority: 'High',
              estimatedMinutes: 30),
        ));
      }
    }
    return QualitySupport.qualityResult(
        name, 'Cyclomatic and cognitive complexity checks.', issues);
  }
}
