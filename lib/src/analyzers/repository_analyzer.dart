import 'analyzer.dart';
import 'analyzer_result.dart';
import 'issue.dart';
import '../core/project_context.dart';
import '../services/file_scanner.dart';

/// Audits repository files and version-control hygiene.
class RepositoryAnalyzer implements Analyzer {
  /// Creates a repository analyzer backed by [scanner].
  RepositoryAnalyzer([this.scanner]);

  /// Scanner used to inspect repository files.
  final FileScanner? scanner;

  /// Report section title for repository checks.
  @override
  String get name => 'REPOSITORY AUDIT';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <Issue>[];
    for (final file in context.scanner.allFiles(context)) {
      final name = file.path.split(RegExp(r'[/\\]')).last;
      if (name == '.env' || name == 'google-services.json') {
        issues.add(Issue(
            severity: Severity.high,
            problem: 'Potential secret-bearing file is present.',
            reason: 'Credentials can be committed or distributed accidentally.',
            files: [file.path],
            recommendedFix:
                'Remove secrets from source control and add the file to .gitignore.',
            priority: 'Immediate'));
      }
    }
    return AnalyzerResult(
        analyzer: name, summary: 'Repository hygiene checks.', issues: issues);
  }
}
