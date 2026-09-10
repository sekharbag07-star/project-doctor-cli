import 'dart:io';

import 'report_document.dart';
import 'section_formatter.dart';
import 'score_formatter.dart';
import 'text_formatter.dart';
import 'toc_generator.dart';

/// Coordinates report formatters without owning filesystem operations.
class ReportFormatter {
  /// Creates a report formatter with replaceable formatting components.
  const ReportFormatter({
    this.text = const TextFormatter(),
    this.section = const SectionFormatter(),
    this.score = const ScoreFormatter(),
    this.toc = const TocGenerator(),
  });

  /// Text formatter.
  final TextFormatter text;

  /// Section formatter.
  final SectionFormatter section;

  /// Score formatter.
  final ScoreFormatter score;

  /// Table-of-contents generator.
  final TocGenerator toc;

  /// Streams [document] into [sink].
  Future<void> write(ReportDocument document, IOSink sink) async {
    final metadata = document.metadata;
    text.writeLine(sink, 'PROJECT DOCTOR REPORT');
    text.writeLine(sink, 'Tool version: ${metadata.doctorVersion}');
    text.writeLine(
        sink, 'Execution timestamp: ${metadata.generatedAt.toIso8601String()}');
    text.writeLine(sink, 'Project path: ${metadata.projectLocation}');
    text.writeLine(sink,
        'Total execution time: ${metadata.executionDuration.inMilliseconds} ms');
    text.writeLine(sink, '=' * 80);
    text.blankLine(sink);
    text.writeLine(sink, 'TABLE OF CONTENTS');
    for (final entry in toc.generate(document.sections)) {
      text.writeLine(sink, entry);
    }
    text.blankLine(sink);
    text.writeLine(sink, 'SUMMARY');
    text.writeLine(sink, 'Analyzers: ${document.sections.length}');
    text.writeLine(sink,
        'Failures: ${document.sections.where((section) => section.body.contains('Analyzer failed')).length}');
    text.blankLine(sink);
    for (final reportSection in document.sections) {
      section.write(sink, reportSection);
    }
    text.writeLine(sink, 'FINAL HEALTH SCORE');
    text.writeLine(sink, 'Overall: ${document.healthScore}/100');
    text.writeLine(sink, score.format(document.healthScore));
    text.blankLine(sink);
    text.writeLine(sink, 'RECOMMENDATIONS');
    for (final recommendation in document.recommendations) {
      text.writeLine(sink, '- $recommendation');
    }
  }
}
