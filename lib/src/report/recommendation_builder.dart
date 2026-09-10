import '../analyzers/analyzer_result.dart';
import '../analyzers/issue.dart';

/// Builds prioritized recommendation data without formatting concerns.
class RecommendationBuilder {
  /// Collects high, medium, and low priority recommendations from [results].
  List<String> build(Iterable<AnalyzerResult> results) {
    final issues = results.expand((result) => result.issues).toList();
    issues.sort((left, right) =>
        _severityRank(left.severity).compareTo(_severityRank(right.severity)));
    return List.unmodifiable(issues
        .where((issue) => issue.severity.index <= Severity.low.index)
        .map((issue) => '[${issue.priority}] ${issue.recommendedFix}'));
  }

  int _severityRank(Severity severity) => severity.index;
}
