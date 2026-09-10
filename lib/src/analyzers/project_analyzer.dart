import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/project_context.dart';

/// Provides a high-level summary of the audited project.
class ProjectAnalyzer implements Analyzer {
  /// Identifies the project information report section.
  @override
  String get name => 'PROJECT INFORMATION';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final files = context
        .children()
        .map((e) => e.path.split(RegExp(r'[/\\]')).last)
        .join(', ');
    return AnalyzerResult(
        analyzer: name,
        summary: 'Project root and top-level entries.',
        data: {
          'Path': context.path,
          'Entries': files.isEmpty ? 'None' : files
        });
  }
}
