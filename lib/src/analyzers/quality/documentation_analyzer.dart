import '../analyzer.dart';
import '../analyzer_result.dart';
import '../issue.dart';
import 'quality_models.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Measures DartDoc coverage for public declarations.
class DocumentationAnalyzer implements Analyzer {
  /// Creates a documentation analyzer.
  DocumentationAnalyzer();
  @override
  String get name => 'DOCUMENTATION';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final inventory = await QualitySupport.inventory(context);
    var documented = 0;
    var declarations = 0;
    for (final source in inventory.contents.values) {
      declarations += RegExp(r'\b(?:class|enum|typedef|void|Future)\s+\w+')
          .allMatches(source)
          .length;
      documented += RegExp(r'///').allMatches(source).length;
    }
    final coverage =
        declarations == 0 ? 100 : (documented / declarations * 100).round();
    final issues = coverage < 60
        ? [
            CodeIssue(
                id: 'docs.coverage',
                title: 'Low public API documentation coverage',
                description: 'DartDoc coverage is below 60%.',
                severity: Severity.medium,
                category: QualityCategory.documentation,
                issueType: IssueType.missingDocumentation,
                locations: const [],
                recommendation: const Recommendation(
                    problem: 'Missing documentation',
                    reason: 'Undocumented APIs increase onboarding cost.',
                    impact: 'Consumers rely on source inspection.',
                    suggestedFix:
                        'Document public classes, methods, and examples.',
                    example: 'Add /// comments before public declarations.',
                    priority: 'Normal',
                    estimatedMinutes: 30))
          ]
        : <CodeIssue>[];
    return QualitySupport.qualityResult(
        name, 'Public API documentation coverage.', issues,
        data: {'Documentation': '$coverage%'});
  }
}
