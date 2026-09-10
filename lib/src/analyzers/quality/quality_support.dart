import 'dart:math' as math;

import '../../core/project_context.dart';
import '../architecture_analysis_support.dart';
import '../analyzer_result.dart';
import '../finding.dart';
import '../source_inventory.dart';
import 'quality_models.dart';

/// Shared quality analysis helpers backed by SourceInventory.
class QualitySupport {
  /// Loads source inventory once for an audit.
  static Future<SourceInventory> inventory(ProjectContext context) =>
      loadSourceInventory(context);

  /// Creates a quality analyzer result from code issues.
  static AnalyzerResult qualityResult(
          String name, String summary, Iterable<CodeIssue> issues,
          {Map<String, String> data = const {}}) =>
      findingResult(
          name,
          summary,
          issues.map((issue) => Finding(
                id: issue.id,
                title: issue.title,
                description: issue.description,
                severity: issue.severity,
                category: issue.category.name,
                priority: _priority(issue.recommendation.priority),
                affectedFiles:
                    issue.locations.map((location) => location.file).toList(),
                recommendation: issue.recommendation.suggestedFix,
              )),
          data: data);

  /// Computes lightweight metrics without AST dependencies.
  static CodeMetric metrics(String source, int dependencyCount) {
    final lines = source.split('\n');
    final sourceLines = lines.where((line) {
      final trimmed = line.trim();
      return trimmed.isNotEmpty && !trimmed.startsWith('//');
    }).length;
    final comments = lines.where((line) => line.trim().startsWith('//')).length;
    final functions = RegExp(r'\b\w+\s*\([^)]*\)\s*(?:async\s*)?\{')
        .allMatches(source)
        .toList();
    final classes = RegExp(r'\bclass\s+\w+').allMatches(source).length;
    final nesting = _maxNesting(source);
    final complexity = 1 +
        RegExp(r'\b(if|for|while|case|catch|\?|&&|\|\|)\b')
            .allMatches(source)
            .length;
    final cognitive = complexity + nesting;
    final mi = (100 - math.min(100, lines.length / 20 + complexity * 1.5))
        .clamp(0, 100)
        .toDouble();
    return CodeMetric(
      linesOfCode: lines.length,
      sourceLines: sourceLines,
      commentRatio: sourceLines == 0 ? 0 : comments / sourceLines,
      documentationPercent: _documentationPercent(source),
      averageFunctionSize:
          functions.isEmpty ? 0 : lines.length / functions.length,
      averageClassSize: classes == 0 ? 0 : lines.length / classes,
      averageNesting: nesting.toDouble(),
      averageParameters: _averageParameters(source),
      dependencyCount: dependencyCount,
      fileFanIn: 0,
      fileFanOut: dependencyCount,
      cyclomaticComplexity: complexity.toDouble(),
      cognitiveComplexity: cognitive.toDouble(),
      maintainabilityIndex: mi,
    );
  }

  static FindingPriority _priority(String value) {
    switch (value.toLowerCase()) {
      case 'immediate':
        return FindingPriority.immediate;
      case 'high':
        return FindingPriority.high;
      case 'low':
        return FindingPriority.low;
      default:
        return FindingPriority.normal;
    }
  }

  static int _maxNesting(String source) {
    var current = 0;
    var maximum = 0;
    for (final character in source.split('')) {
      if (character == '{') {
        current++;
        maximum = math.max(maximum, current);
      } else if (character == '}') {
        current = math.max(0, current - 1);
      }
    }
    return maximum;
  }

  static double _averageParameters(String source) {
    final matches = RegExp(r'\(([^()]*)\)').allMatches(source);
    if (matches.isEmpty) return 0;
    final total = matches.fold<int>(0, (sum, match) {
      final value = match.group(1)!.trim();
      return sum + (value.isEmpty ? 0 : value.split(',').length);
    });
    return total / matches.length;
  }

  static double _documentationPercent(String source) {
    final declarations = RegExp(
            r'\b(class|enum|typedef|abstract class|void|Future<[^>]+>)\s+\w+')
        .allMatches(source)
        .length;
    if (declarations == 0) return 100;
    final docs = RegExp(r'///').allMatches(source).length;
    return math.min(100, docs / declarations * 100);
  }
}
