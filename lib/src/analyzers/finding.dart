import 'issue.dart';

/// Priority assigned to a structured architecture finding.
enum Priority {
  /// Minor issue.
  low,

  /// Standard issue.
  normal,

  /// Important issue.
  high,

  /// Urgent issue.
  immediate,
}

/// Immutable structured finding produced by Phase 5 analyzers.
class Finding {
  /// Creates a structured finding.
  Finding({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.priority,
    required List<String> affectedFiles,
    required this.recommendation,
  }) : affectedFiles = List.unmodifiable(affectedFiles);

  /// Stable finding identifier.
  final String id;

  /// Short finding title.
  final String title;

  /// Detailed explanation.
  final String description;

  /// Finding severity.
  final Severity severity;

  /// Analyzer category that produced this finding.
  final String category;

  /// Remediation urgency.
  final FindingPriority priority;

  /// Files associated with the finding.
  final List<String> affectedFiles;

  /// Recommended remediation.
  final String recommendation;

  /// Converts this finding to the legacy report issue model.
  Issue toIssue() => Issue(
        severity: severity,
        problem: title,
        reason: description,
        files: affectedFiles,
        recommendedFix: recommendation,
        priority: priority.name,
      );
}

/// Backward-compatible descriptive alias for [Priority].
typedef FindingPriority = Priority;
