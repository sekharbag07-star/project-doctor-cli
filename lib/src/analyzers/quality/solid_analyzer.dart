import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects common SOLID and dependency inversion smells.
class SolidAnalyzer implements Analyzer {
  /// Creates a SOLID analyzer.
  SolidAnalyzer();
  @override
  String get name => 'SOLID DESIGN';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      if (entry.value.contains('new ') && entry.value.contains('class ')) {
        issues.add(CodeIssue(
            id: 'solid.dip.${entry.key}',
            title: 'Concrete construction in service code',
            description:
                'Direct construction can couple policy code to infrastructure.',
            severity: Severity.low,
            category: QualityCategory.architecture,
            issueType: IssueType.solidViolation,
            locations: [CodeLocation(file: entry.key)],
            recommendation: const Recommendation(
                problem: 'Dependency inversion smell',
                reason:
                    'Concrete dependencies reduce substitution and testability.',
                impact:
                    'Mocks and alternate implementations become harder to introduce.',
                suggestedFix: 'Inject abstractions through constructors.',
                example:
                    'Depend on an interface instead of a concrete service.',
                priority: 'Low',
                estimatedMinutes: 20)));
      }
    }
    return QualitySupport.qualityResult(
        name, 'SOLID design and dependency inversion checks.', issues);
  }
}
