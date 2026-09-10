import 'analyzer.dart';
import 'analyzer_result.dart';
import 'issue.dart';
import '../core/project_context.dart';
import '../services/file_scanner.dart';

/// Checks that presentation code does not depend directly on data code.
class ArchitectureAnalyzer implements Analyzer {
  /// Creates an architecture analyzer backed by [scanner].
  ArchitectureAnalyzer(this.scanner);

  /// Scanner used to inspect Dart source files.
  final FileScanner scanner;

  /// Report section title for the architecture audit.
  @override
  String get name => 'ARCHITECTURE AUDIT';

  /// Runs the presentation-to-data dependency check.
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <Issue>[];
    for (final file in scanner.dartFiles(context)) {
      final text = file.readAsStringSync();
      final normalized = file.path.replaceAll('\\', '/');
      if (normalized.contains('/presentation/') && text.contains('/data/')) {
        issues.add(Issue(
            severity: Severity.high,
            problem: 'Presentation layer imports data layer.',
            reason:
                'This couples UI code to infrastructure and weakens dependency direction.',
            files: [normalized],
            recommendedFix:
                'Depend on domain abstractions and inject data implementations.',
            priority: 'Immediate'));
      }
    }
    return AnalyzerResult(
        analyzer: name,
        summary: 'Layer import direction checks.',
        issues: issues);
  }
}
