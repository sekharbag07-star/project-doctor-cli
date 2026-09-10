import 'dart:convert';
import 'dart:io';

import 'report_document.dart';
import 'report_formatter.dart';

/// Owns report file creation and progressive UTF-8 writing.
class ReportWriter {
  /// Creates a writer with a replaceable formatter.
  const ReportWriter({this.formatter = const ReportFormatter()});

  /// Formatter used to stream document content.
  final ReportFormatter formatter;

  /// Creates a timestamped report file inside [directory] and writes [document].
  Future<File> writeToDirectory(
      {required Directory directory,
      required ReportDocument document,
      DateTime? timestamp}) async {
    await directory.create(recursive: true);
    final time = timestamp ?? DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}${two(time.second)}';
    final file = File(
        '${directory.path}${Platform.pathSeparator}project_report_$stamp.txt');
    await write(file: file, document: document);
    return file;
  }

  /// Creates [file]'s parent directory and writes [document] as UTF-8.
  Future<void> write(
      {required File file, required ReportDocument document}) async {
    await file.parent.create(recursive: true);
    final sink = file.openWrite(encoding: utf8);
    try {
      await formatter.write(document, sink);
    } finally {
      await sink.flush();
      await sink.close();
    }
  }
}
