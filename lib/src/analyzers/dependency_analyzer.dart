import 'dart:io';
import 'analyzer.dart';
import 'analyzer_result.dart';
import '../core/command_runner.dart';
import '../core/project_context.dart';

/// Inspects the package manifest and reports outdated dependencies.
class DependencyAnalyzer implements Analyzer {
  /// Creates a dependency analyzer using [runner].
  DependencyAnalyzer(this.runner);

  /// Process runner used to invoke package tooling.
  final CommandRunner runner;

  /// Report section title for dependency analysis.
  @override
  String get name => 'DEPENDENCY REPORT';

  /// Reads `pubspec.yaml` and requests outdated package information.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final pubspec =
        File('${context.path}${Platform.pathSeparator}pubspec.yaml');
    if (!pubspec.existsSync()) {
      return AnalyzerResult(analyzer: name, summary: 'No pubspec.yaml found.');
    }
    final lines = pubspec.readAsLinesSync();
    final dependencies = lines
        .where((line) => line.startsWith('  ') && line.trim().contains(':'))
        .length;
    final outdated = await runner.run('flutter', ['pub', 'outdated'],
        workingDirectory: context.path);
    return AnalyzerResult(
        analyzer: name,
        summary: 'Package manifest inspection.',
        data: {
          'Declared packages': '$dependencies',
          'Outdated': outdated.succeeded ? outdated.stdout : 'Unavailable'
        });
  }
}
