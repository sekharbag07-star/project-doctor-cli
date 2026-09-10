import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/project_context.dart';

/// Provides a named report section for an audit without custom logic.
class SectionAnalyzer implements Analyzer {
  /// Creates a section with its report [name] and [summary].
  SectionAnalyzer(this.name, this.summary);

  /// Report section name.
  @override
  final String name;

  /// Summary text returned when the section runs.
  final String summary;

  /// Returns the configured section without additional findings.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async =>
      AnalyzerResult(analyzer: name, summary: summary);
}
