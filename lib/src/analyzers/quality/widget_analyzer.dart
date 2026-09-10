import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects large Flutter widgets and complex build methods.
class WidgetAnalyzer implements Analyzer {
  /// Creates a widget analyzer.
  WidgetAnalyzer();
  @override
  String get name => 'FLUTTER QUALITY';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      final content = entry.value;
      if (content.contains('extends StatelessWidget') ||
          content.contains('extends StatefulWidget')) {
        if (content.split('\n').length > context.configuration.maxWidgetLines) {
          issues.add(CodeIssue(
              id: 'widget.large.${entry.key}',
              title: 'Large Flutter widget',
              description:
                  'Widget source exceeds the configured size threshold.',
              severity: Severity.medium,
              category: QualityCategory.flutter,
              issueType: IssueType.widgetComplexity,
              locations: [CodeLocation(file: entry.key)],
              recommendation: const Recommendation(
                  problem: 'Large widget',
                  reason: 'Large widgets combine presentation and behavior.',
                  impact: 'Rebuilds and tests become harder to reason about.',
                  suggestedFix: 'Extract focused widgets and view-model logic.',
                  example: 'Split build sections into const child widgets.',
                  priority: 'Normal',
                  estimatedMinutes: 45)));
        }
      }
    }
    return QualitySupport.qualityResult(
        name, 'Flutter widget size and build checks.', issues);
  }
}
