import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/command_runner.dart';
import '../core/project_context.dart';

/// Runs Flutter doctor and analyzer diagnostics for the target project.
class FlutterAnalyzer implements Analyzer {
  /// Creates a Flutter analyzer using [runner].
  FlutterAnalyzer([this.runner]);

  /// Process runner used to invoke Flutter tooling.
  final CommandRunner? runner;

  /// Report section title for Flutter diagnostics.
  @override
  String get name => 'FLUTTER DOCTOR / ANALYZE';

  /// Executes Flutter doctor and Flutter analysis.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final doctor = await context.commandRunner
        .run('flutter', ['doctor', '-v'], workingDirectory: context.path);
    final analyze = await context.commandRunner
        .run('flutter', ['analyze'], workingDirectory: context.path);
    return AnalyzerResult(
        analyzer: name,
        summary: 'Flutter tool diagnostics.',
        data: {
          'Flutter doctor': doctor.succeeded
              ? 'Passed'
              : doctor.stderr.isEmpty
                  ? 'Issues detected'
                  : doctor.stderr,
          'Flutter analyze': analyze.succeeded ? 'Passed' : 'Issues detected',
        });
  }
}
