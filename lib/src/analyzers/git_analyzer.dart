import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/command_runner.dart';
import '../core/project_context.dart';

/// Reports Git status, branches, recent history, and diff statistics.
class GitAnalyzer implements Analyzer {
  /// Creates a Git analyzer using [runner].
  GitAnalyzer(this.runner);

  /// Process runner used to invoke Git commands.
  final CommandRunner runner;

  /// Report section title for repository diagnostics.
  @override
  String get name => 'GIT STATUS / BRANCHES / HISTORY / DIFF';

  /// Collects a concise snapshot of the repository state.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final commands = <String, List<String>>{
      'Status': ['status', '--short'],
      'Branches': ['branch', '-a'],
      'History': ['log', '-5', '--oneline'],
      'Diff summary': ['diff', '--stat'],
    };
    final data = <String, String>{};
    for (final entry in commands.entries) {
      final result =
          await runner.run('git', entry.value, workingDirectory: context.path);
      data[entry.key] = result.succeeded
          ? (result.stdout.isEmpty ? 'Clean / none' : result.stdout)
          : 'Unavailable';
    }
    return AnalyzerResult(
        analyzer: name,
        summary: 'Repository state and recent history.',
        data: data);
  }
}
