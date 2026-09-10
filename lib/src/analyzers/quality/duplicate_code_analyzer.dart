import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Detects repeated normalized token windows in Dart source.
class DuplicateCodeAnalyzer implements Analyzer {
  /// Creates a duplicate detector with a minimum token count.
  DuplicateCodeAnalyzer({this.minimumTokens = 12});

  /// Minimum repeated token window size.
  final int minimumTokens;
  @override
  String get name => 'DUPLICATE CODE';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final inventory = await QualitySupport.inventory(context);
    final hashes = <String, String>{};
    final issues = <CodeIssue>[];
    for (final entry in inventory.contents.entries) {
      final tokens = RegExp(r'[A-Za-z_][A-Za-z0-9_]*|[{}();=]')
          .allMatches(entry.value)
          .map((m) => m.group(0)!)
          .toList();
      for (var index = 0;
          index + minimumTokens <= tokens.length;
          index += minimumTokens) {
        final window = tokens.sublist(index, index + minimumTokens).join(' ');
        final previous = hashes[window];
        if (previous != null && previous != entry.key) {
          issues.add(CodeIssue(
            id: 'duplicate.$previous.${entry.key}.$index',
            title: 'Duplicate code detected',
            description: 'The same token sequence appears in multiple files.',
            severity: Severity.medium,
            category: QualityCategory.duplication,
            issueType: IssueType.duplicateCode,
            locations: [
              CodeLocation(file: previous),
              CodeLocation(file: entry.key)
            ],
            recommendation: const Recommendation(
                problem: 'Duplicate code',
                reason: 'Repeated logic drifts over time.',
                impact: 'Maintenance fixes must be repeated.',
                suggestedFix: 'Extract shared behavior into one abstraction.',
                example: 'Create a shared helper or service.',
                priority: 'Normal',
                estimatedMinutes: 30),
          ));
          break;
        }
        hashes[window] = entry.key;
      }
    }
    return QualitySupport.qualityResult(
        name, 'Token-based duplicate code checks.', issues);
  }
}
