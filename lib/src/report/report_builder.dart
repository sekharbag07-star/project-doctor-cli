import 'dart:io';

import '../analyzers/analyzer_result.dart';
import 'recommendation_builder.dart';
import 'report_document.dart';
import 'report_metadata.dart';
import 'report_writer.dart';
import 'section_registry.dart';
import 'score_calculator.dart';

/// Builds immutable report documents and preserves the legacy write API.
class ReportBuilder {
  /// Creates a builder using the supplied score calculator.
  ReportBuilder(this.scoreCalculator,
      {SectionRegistry? sectionRegistry,
      RecommendationBuilder? recommendationBuilder,
      ReportWriter? writer})
      : sectionRegistry = sectionRegistry ?? SectionRegistry.standard(),
        recommendationBuilder =
            recommendationBuilder ?? RecommendationBuilder(),
        writer = writer ?? const ReportWriter();

  /// Calculator used to produce the final health score.
  final ScoreCalculator scoreCalculator;

  /// Registry that creates report sections.
  final SectionRegistry sectionRegistry;

  /// Builder for prioritized recommendations.
  final RecommendationBuilder recommendationBuilder;

  /// Writer used by the compatibility method.
  final ReportWriter writer;

  /// Builds an immutable report document from analyzer [results].
  ReportDocument build({
    required List<AnalyzerResult> results,
    required DateTime startedAt,
    String version = '1.0.0',
    String projectPath = '',
    Duration totalDuration = Duration.zero,
  }) {
    final projectName = projectPath.isEmpty
        ? ''
        : projectPath
            .split(RegExp(r'[/\\]'))
            .where((part) => part.isNotEmpty)
            .last;
    return ReportDocument(
      metadata: ReportMetadata(
        projectName: projectName,
        generatedAt: startedAt,
        doctorVersion: version,
        projectLocation: projectPath,
        executionDuration: totalDuration,
        operatingSystem: Platform.operatingSystem,
      ),
      sections: sectionRegistry.build(results),
      recommendations: recommendationBuilder.build(results),
      healthScore: scoreCalculator.calculate(results),
    );
  }

  /// Writes [results] and execution metadata to [file].
  Future<void> write({
    required File file,
    required List<AnalyzerResult> results,
    required DateTime startedAt,
    String version = '1.0.0',
    String projectPath = '',
    Duration totalDuration = Duration.zero,
  }) async {
    final document = build(
      results: results,
      startedAt: startedAt,
      version: version,
      projectPath: projectPath,
      totalDuration: totalDuration,
    );
    await writer.write(file: file, document: document);
  }

  /// Builds and writes a timestamped report inside [directory].
  Future<File> writeToDirectory({
    required Directory directory,
    required List<AnalyzerResult> results,
    required DateTime startedAt,
    String version = '1.0.0',
    String projectPath = '',
    Duration totalDuration = Duration.zero,
  }) {
    final document = build(
      results: results,
      startedAt: startedAt,
      version: version,
      projectPath: projectPath,
      totalDuration: totalDuration,
    );
    return writer.writeToDirectory(
        directory: directory, document: document, timestamp: startedAt);
  }
}
