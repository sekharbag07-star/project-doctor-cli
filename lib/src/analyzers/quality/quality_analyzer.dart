import '../analyzer.dart';
import '../analyzer_result.dart';
import 'quality_support.dart';
import '../../core/project_context.dart';

/// Produces the aggregate code quality score from cached source metrics.
class QualityAnalyzer implements Analyzer {
  /// Creates a quality analyzer.
  QualityAnalyzer();
  @override
  String get name => 'CODE QUALITY';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final inventory = await QualitySupport.inventory(context);
    var total = 0.0;
    for (final source in inventory.contents.values) {
      total += QualitySupport.metrics(source, 0).maintainabilityIndex;
    }
    final score = inventory.contents.isEmpty
        ? 100
        : (total / inventory.contents.length).round();
    return AnalyzerResult(
        analyzer: name,
        summary: 'Overall code quality score.',
        data: {
          'Maintainability Score': '$score',
          'Overall Score': '$score/100'
        });
  }
}
