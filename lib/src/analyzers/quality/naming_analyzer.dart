import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Checks common Dart declaration naming conventions.
class NamingAnalyzer implements Analyzer {
  /// Creates a naming analyzer.
  NamingAnalyzer();
  @override
  String get name => 'NAMING';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      for (final match in RegExp(r'\bclass\s+([a-z][A-Za-z0-9_]*)')
          .allMatches(entry.value)) {
        issues.add(CodeIssue(
            id: 'naming.${entry.key}.${match.start}',
            title: 'Class name should be UpperCamelCase',
            description: 'Dart classes should use UpperCamelCase.',
            severity: Severity.low,
            category: QualityCategory.naming,
            issueType: IssueType.naming,
            locations: [CodeLocation(file: entry.key)],
            recommendation: const Recommendation(
                problem: 'Naming violation',
                reason: 'Consistent names improve discoverability.',
                impact: 'Code search and API comprehension suffer.',
                suggestedFix: 'Rename the class using UpperCamelCase.',
                example: 'class UserProfile {}',
                priority: 'Low',
                estimatedMinutes: 5)));
      }
    }
    return QualitySupport.qualityResult(
        name, 'Dart naming convention checks.', issues);
  }
}
