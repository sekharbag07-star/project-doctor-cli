import 'report_metadata.dart';
import 'report_section.dart';

/// Immutable report data ready for formatting and writing.
class ReportDocument {
  /// Creates a report document from immutable report components.
  ReportDocument({
    required this.metadata,
    required List<ReportSection> sections,
    required List<String> recommendations,
    required this.healthScore,
  })  : sections = List.unmodifiable(sections),
        recommendations = List.unmodifiable(recommendations);

  /// Report metadata.
  final ReportMetadata metadata;

  /// Ordered report sections.
  final List<ReportSection> sections;

  /// Prioritized plain-text recommendations.
  final List<String> recommendations;

  /// Overall health score from 0 to 100.
  final int healthScore;
}
