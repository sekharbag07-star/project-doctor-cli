/// Severity levels used to prioritize audit findings.
enum Severity {
  /// A finding that threatens core operation or safety.
  critical,

  /// A finding that should be addressed immediately.
  high,

  /// A finding with meaningful but non-blocking impact.
  medium,

  /// A minor improvement or maintainability concern.
  low,

  /// Informational context with no score deduction.
  info
}

/// Describes one actionable problem found during an audit.
class Issue {
  /// Creates an issue and the remediation guidance shown in reports.
  const Issue(
      {required this.severity,
      required this.problem,
      required this.reason,
      required this.files,
      required this.recommendedFix,
      required this.priority});

  /// Priority category used for scoring and sorting recommendations.
  final Severity severity;

  /// Concise statement of the detected problem.
  final String problem;

  /// Explanation of the problem's practical impact.
  final String reason;

  /// Project-relative or absolute files related to the issue.
  final List<String> files;

  /// Suggested action for resolving the issue.
  final String recommendedFix;

  /// Human-readable urgency label.
  final String priority;

  /// Returns the severity name in the uppercase form used by reports.
  String get severityLabel => severity.name.toUpperCase();
}
