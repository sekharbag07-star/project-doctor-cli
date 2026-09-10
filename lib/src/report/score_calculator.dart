import '../analyzers/analyzer_result.dart';

/// Aggregates analyzer scores into one rounded project health score.
class ScoreCalculator {
  /// Weights applied to the built-in analyzer sections.
  static const weights = <String, double>{
    'ARCHITECTURE AUDIT': 0.25,
    'SECURITY AUDIT': 0.25,
    'QUALITY / TODO / DUPLICATE / DEPRECATED REPORT': 0.15,
    'PERFORMANCE AUDIT': 0.15,
    'DEPENDENCY REPORT': 0.10,
    'GIT STATUS / BRANCHES / HISTORY / DIFF': 0.05,
    'ENVIRONMENT': 0.05,
  };

  /// Calculates the average score of successful analyzer results.
  int calculate(Iterable<AnalyzerResult> results) {
    final successful = results.where((result) => !result.failed).toList();
    final weighted = successful
        .where((result) => weights.containsKey(result.analyzer))
        .toList();
    if (weighted.isNotEmpty) {
      final totalWeight = weighted.fold<double>(
          0, (total, result) => total + weights[result.analyzer]!);
      final weightedScore = weighted.fold<double>(0,
          (total, result) => total + result.score * weights[result.analyzer]!);
      if (totalWeight > 0) return (weightedScore / totalWeight).round();
    }
    final scores = successful.map((result) => result.score).toList();
    if (scores.isEmpty) return 0;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }
}
