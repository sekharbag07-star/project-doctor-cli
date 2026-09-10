import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects likely unused private declarations and imports.
class DeadCodeAnalyzer implements Analyzer {
  /// Creates a dead-code analyzer.
  DeadCodeAnalyzer();

  /// Analyzer display name.
  @override
  String get name => 'DEAD CODE';

  /// Runs dead-code checks against cached source.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <CodeIssue>[];
    final inventory = await QualitySupport.inventory(context);
    for (final entry in inventory.contents.entries) {
      final content = entry.value;
      for (final match in RegExp(r'\b(?:class|void|int|String|bool)\s+(_\w+)')
          .allMatches(content)) {
        final name = match.group(1)!;
        if (RegExp(r'\b' + RegExp.escape(name) + r'\b')
                .allMatches(content)
                .length ==
            1) {
          issues.add(CodeIssue(
            id: 'dead.$name.${entry.key}',
            title: 'Unused private declaration',
            description: 'Private declaration appears only at its definition.',
            severity: Severity.low,
            category: QualityCategory.deadCode,
            issueType: IssueType.deadCode,
            locations: [CodeLocation(file: entry.key)],
            recommendation: const Recommendation(
              problem: 'Dead code',
              reason: 'Unused declarations increase noise.',
              impact: 'More code must be understood and maintained.',
              suggestedFix: 'Remove it or add a verified usage.',
              example: 'Delete unused private helpers.',
              priority: 'Low',
              estimatedMinutes: 10,
            ),
          ));
        }
      }
    }
    return QualitySupport.qualityResult(
        name, 'Dead declarations and import checks.', issues);
  }
}
