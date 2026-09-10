import '../analyzer.dart';
import '../analyzer_result.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Produces aggregate quality metrics and maintainability score.
class MaintainabilityAnalyzer implements Analyzer {
  /// Creates a maintainability analyzer.
  MaintainabilityAnalyzer();
  @override
  String get name => 'MAINTAINABILITY';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final inventory = await QualitySupport.inventory(context);
    var lines = 0;
    var sourceLines = 0;
    var complexity = 0.0;
    var maintainability = 0.0;
    for (final source in inventory.contents.values) {
      final metric = QualitySupport.metrics(source, 0);
      lines += metric.linesOfCode;
      sourceLines += metric.sourceLines;
      complexity += metric.cyclomaticComplexity;
      maintainability += metric.maintainabilityIndex;
    }
    final count = inventory.contents.isEmpty ? 1 : inventory.contents.length;
    return AnalyzerResult(
        analyzer: name,
        summary: 'Aggregate code quality metrics.',
        data: {
          'LOC': '$lines',
          'SLOC': '$sourceLines',
          'Average complexity': '${(complexity / count).round()}',
          'Maintainability Index': '${(maintainability / count).round()}',
          'Quality Score': '${(maintainability / count).round()}/100'
        });
  }
}
