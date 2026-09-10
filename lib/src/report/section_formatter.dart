import 'report_section.dart';
import 'text_formatter.dart';

/// Formats one report section as streamed text.
class SectionFormatter {
  /// Creates a section formatter.
  const SectionFormatter({this.text = const TextFormatter()});

  /// Text formatting helper.
  final TextFormatter text;

  /// Writes [section] to [sink].
  void write(StringSink sink, ReportSection section) {
    text.writeLine(sink, section.title);
    text.writeLine(sink, '-' * section.title.length);
    text.writeLine(sink, section.body);
    text.blankLine(sink);
  }
}
