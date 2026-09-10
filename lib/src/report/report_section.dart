import '../analyzers/issue.dart';

/// Immutable report section produced from one analyzer result.
class ReportSection {
  /// Creates a report section.
  const ReportSection({
    required this.id,
    required this.title,
    required this.order,
    required this.severity,
    required this.body,
  });

  /// Stable section identifier.
  final String id;

  /// Human-readable section title.
  final String title;

  /// Ordering value used by registries and formatters.
  final int order;

  /// Highest severity found in the section.
  final Severity severity;

  /// Plain text body written by the report formatter.
  final String body;
}
