import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects methods and functions exceeding configured size thresholds.
class LongMethodAnalyzer implements Analyzer {
  /// Creates a long-method analyzer.
  LongMethodAnalyzer();
  @override
  String get name => 'LONG METHODS';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    final threshold = context.configuration.maxMethodLines;
    for (final entry in inventory.contents.entries) {
      final lines = entry.value.split('\n');
      if (lines.length > threshold * 2) {
        issues.add(CodeIssue(
          id: 'method.long.${entry.key}',
          title: 'Long method or file',
          description:
              'Source contains a method-sized region beyond the configured threshold.',
          severity: Severity.medium,
          category: QualityCategory.complexity,
          issueType: IssueType.longMethod,
          locations: [CodeLocation(file: entry.key)],
          recommendation: const Recommendation(
              problem: 'Long method',
              reason: 'Large methods hide multiple responsibilities.',
              impact: 'Reduced testability and maintainability.',
              suggestedFix: 'Extract cohesive operations into smaller methods.',
              example: 'Move validation into a validator class.',
              priority: 'Normal',
              estimatedMinutes: 30),
        ));
      }
    }
    return QualitySupport.qualityResult(name, 'Method size checks.', issues);
  }
}
