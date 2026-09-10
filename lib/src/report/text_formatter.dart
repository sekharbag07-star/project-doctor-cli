/// Formats plain text lines for report output.
class TextFormatter {
  /// Creates a text formatter.
  const TextFormatter();

  /// Writes [text] with a trailing newline to [sink].
  void writeLine(StringSink sink, [String text = '']) => sink.write('$text\n');

  /// Writes a blank line to [sink].
  void blankLine(StringSink sink) => writeLine(sink);

  /// Wraps [text] to [width] columns without changing words where possible.
  Iterable<String> wrap(String text, {int width = 80}) sync* {
    if (text.isEmpty) {
      yield '';
      return;
    }
    var line = StringBuffer();
    for (final word in text.split(RegExp(r'\s+'))) {
      if (line.isNotEmpty && line.length + word.length + 1 > width) {
        yield line.toString();
        line = StringBuffer(word);
      } else {
        if (line.isNotEmpty) line.write(' ');
        line.write(word);
      }
    }
    if (line.isNotEmpty) yield line.toString();
  }
}
