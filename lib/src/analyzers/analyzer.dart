import '../core/project_context.dart';
import 'analyzer_result.dart';

/// Defines one project-health audit that can run against a project context.
abstract interface class Analyzer {
  /// The human-readable section name used in reports.
  String get name;

  /// Runs the audit and returns its findings and measured data.
  Future<AnalyzerResult> analyze(ProjectContext context);
}
