import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/command_runner.dart';
import '../core/project_context.dart';

/// Runs the Dart analyzer command in the target project.
class DartAnalyzer implements Analyzer {
  /// Creates a Dart analyzer using [runner] for process execution.
  DartAnalyzer(this.runner);

  /// Process runner used to invoke `dart analyze`.
  final CommandRunner runner;

  /// Report section title for Dart analysis.
  @override
  String get name => 'DART ANALYZE';

  /// Executes Dart analysis and captures its output.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final result =
        await runner.run('dart', ['analyze'], workingDirectory: context.path);
    return AnalyzerResult(
        analyzer: name,
        summary: result.succeeded
            ? 'Dart analyzer passed.'
            : 'Dart analyzer reported issues.',
        data: {
          'Output': result.stdout.isEmpty ? result.stderr : result.stdout
        });
  }
}
