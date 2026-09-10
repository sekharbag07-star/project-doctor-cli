import 'issue.dart';

/// Contains the outcome, findings, and measurements produced by an analyzer.
class AnalyzerResult {
  /// Creates an analyzer result with optional findings and execution metadata.
  const AnalyzerResult(
      {required this.analyzer,
      required this.summary,
      this.issues = const [],
      this.data = const {},
      this.failed = false,
      this.duration = Duration.zero,
      this.failureDetails,
      this.startedAt,
      this.finishedAt});

  /// Name of the analyzer that produced this result.
  final String analyzer;

  /// Short human-readable description of the audit outcome.
  final String summary;

  /// Issues discovered during the audit.
  final List<Issue> issues;

  /// Additional named measurements displayed in the report.
  final Map<String, String> data;

  /// Whether the analyzer failed instead of completing normally.
  final bool failed;

  /// Time spent running the analyzer.
  final Duration duration;

  /// Diagnostic details captured when the analyzer fails.
  final String? failureDetails;

  /// Time at which analyzer execution began, when available.
  final DateTime? startedAt;

  /// Time at which analyzer execution completed, when available.
  final DateTime? finishedAt;

  /// Number of warning-level findings in [issues].
  int get warnings => issues
      .where((issue) =>
          issue.severity == Severity.low || issue.severity == Severity.medium)
      .length;

  /// Number of error-level findings in [issues].
  int get errors => issues
      .where((issue) =>
          issue.severity == Severity.critical ||
          issue.severity == Severity.high)
      .length;

  /// Calculates a score from 0 to 100 after applying severity deductions.
  double get score {
    if (failed) return 0;
    final deductions = issues.fold<double>(0, (total, issue) {
      switch (issue.severity) {
        case Severity.critical:
          return total + 25;
        case Severity.high:
          return total + 15;
        case Severity.medium:
          return total + 8;
        case Severity.low:
          return total + 3;
        case Severity.info:
          return total;
      }
    });
    return (100 - deductions).clamp(0, 100).toDouble();
  }
}
