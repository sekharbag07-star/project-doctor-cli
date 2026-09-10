import 'report_section.dart';

/// Generates a table of contents from registered report sections.
class TocGenerator {
  /// Creates a table-of-contents generator.
  const TocGenerator();

  /// Returns numbered entries in section order.
  Iterable<String> generate(Iterable<ReportSection> sections) sync* {
    var index = 1;
    for (final section in sections) {
      yield '${index++}. ${section.title}';
    }
  }
}
