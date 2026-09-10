import 'analyzer.dart';
import 'analyzer_result.dart';
import 'issue.dart';
import '../core/project_context.dart';
import '../services/file_scanner.dart';

/// Calculates source size, class, widget, and large-file metrics.
class MetricsAnalyzer implements Analyzer {
  /// Creates a metrics analyzer backed by [scanner].
  MetricsAnalyzer([this.scanner]);

  /// Scanner used to enumerate Dart source files.
  final FileScanner? scanner;

  /// Report section title for project metrics.
  @override
  String get name => 'PROJECT STRUCTURE / FILE STATISTICS / CODE METRICS';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    var lines = 0;
    var classes = 0;
    var widgets = 0;
    var largeFiles = 0;
    final issues = <Issue>[];
    for (final file in context.scanner.dartFiles(context)) {
      final content = file.readAsStringSync();
      final fileLines = content.split('\n').length;
      lines += fileLines;
      classes += RegExp(r'\bclass\s+\w+').allMatches(content).length;
      widgets += RegExp(r'extends\s+(StatelessWidget|StatefulWidget|Widget)')
          .allMatches(content)
          .length;
      if (fileLines > context.configuration.maxWidgetLines ||
          file.lengthSync() >
              context.configuration.maxFileSizeMb * 1024 * 1024) {
        largeFiles++;
        issues.add(Issue(
            severity: Severity.medium,
            problem: 'Large Dart file.',
            reason: 'Large files are harder to review and maintain.',
            files: [file.path],
            recommendedFix: 'Split the file around cohesive responsibilities.',
            priority: 'Planned'));
      }
    }
    return AnalyzerResult(
        analyzer: name,
        summary: 'Source structure and size metrics.',
        issues: issues,
        data: {
          'Dart files': '${context.scanner.dartFiles(context).length}',
          'Lines of code': '$lines',
          'Classes': '$classes',
          'Widgets': '$widgets',
          'Large files': '$largeFiles'
        });
  }
}
