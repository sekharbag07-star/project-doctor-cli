import 'dart:io';
import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/project_context.dart';
import '../services/file_scanner.dart';

/// Summarizes Dart files and top-level feature directories.
class FeatureAnalyzer implements Analyzer {
  /// Creates a feature analyzer backed by [scanner].
  FeatureAnalyzer([this.scanner]);

  /// Scanner used to count Dart files.
  final FileScanner? scanner;

  /// Report section title for feature organization.
  @override
  String get name => 'FEATURE AUDIT';

  /// Measures the project's high-level feature layout.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    var files = 0;
    await for (final entity in context.scanner
        .scan(context, filter: const ScanFilter(extensions: {'.dart'}))) {
      if (entity is File) files++;
    }
    final featureDirectories =
        context.children(relativePath: 'lib').whereType<Directory>().length;
    return AnalyzerResult(
        analyzer: name,
        summary: 'Feature organization overview.',
        data: {
          'Dart files': '$files',
          'Top-level lib directories': '$featureDirectories'
        });
  }
}
