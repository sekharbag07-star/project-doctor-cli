import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/command_runner.dart';
import '../core/project_context.dart';

/// Detects the development tools available on the host machine.
class EnvironmentAnalyzer implements Analyzer {
  /// Creates an environment analyzer using [runner].
  EnvironmentAnalyzer([this.runner]);

  /// Process runner used to query tool versions.
  final CommandRunner? runner;

  /// Report section title for environment checks.
  @override
  String get name => 'ENVIRONMENT';

  /// Queries the version of each supported development tool.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final tools = <String, String>{};
    final commandRunner = context.commandRunner;
    for (final tool in ['dart', 'flutter', 'git', 'java', 'adb', 'code']) {
      final result = await commandRunner.run(tool, ['--version'],
          workingDirectory: context.path);
      tools[tool] =
          result.succeeded ? result.stdout.split('\n').first : 'Not available';
    }
    return AnalyzerResult(
        analyzer: name, summary: 'Development tool availability.', data: tools);
  }
}
