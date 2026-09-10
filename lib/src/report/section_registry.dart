import '../analyzers/analyzer_result.dart';
import '../analyzers/issue.dart';
import 'report_section.dart';

/// Registry that owns report section creation and ordering.
class SectionRegistry {
  /// Creates an empty section registry.
  SectionRegistry();

  final List<ReportSection Function(AnalyzerResult result, int order)>
      _factories = [];

  /// Registers a section factory for analyzer results.
  void register(
      ReportSection Function(AnalyzerResult result, int order) factory) {
    _factories.add(factory);
  }

  /// Creates sections for [results] in registration order.
  List<ReportSection> build(Iterable<AnalyzerResult> results) {
    final sections = <ReportSection>[];
    var order = 0;
    for (final result in results) {
      for (final factory in _factories) {
        sections.add(factory(result, order++));
      }
    }
    sections.sort((left, right) => left.order.compareTo(right.order));
    return List.unmodifiable(sections);
  }

  /// Creates a registry with the standard analyzer-result section factory.
  factory SectionRegistry.standard() {
    final registry = SectionRegistry();
    registry.register((result, order) => ReportSection(
          id: result.analyzer,
          title: result.analyzer,
          order: order,
          severity: result.issues.isEmpty
              ? Severity.info
              : result.issues.map((issue) => issue.severity).reduce(
                  (left, right) => left.index >= right.index ? left : right),
          body: _body(result),
        ));
    return registry;
  }
}

String _body(AnalyzerResult result) {
  final lines = <String>[
    result.summary,
    'Execution time: ${result.duration.inMilliseconds} ms',
    ...result.data.entries.map((entry) => '${entry.key}: ${entry.value}'),
  ];
  if (result.failed) {
    lines.add('Analyzer failed; the remaining audit continued.');
  }
  if (result.failureDetails != null) {
    lines.add('Failure details:\n${result.failureDetails}');
  }
  for (final issue in result.issues) {
    lines.addAll([
      '',
      issue.severityLabel,
      'Problem: ${issue.problem}',
      'Why it matters: ${issue.reason}',
      'Affected files: ${issue.files.isEmpty ? 'None reported' : issue.files.join(', ')}',
      'Recommended fix: ${issue.recommendedFix}',
      'Priority: ${issue.priority}',
    ]);
  }
  return lines.join('\n');
}
