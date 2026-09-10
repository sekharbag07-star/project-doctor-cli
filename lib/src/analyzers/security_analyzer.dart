import 'analyzer.dart';
import 'analyzer_result.dart';
import 'issue.dart';
import '../core/project_context.dart';
import '../services/file_scanner.dart';

/// Scans source files for basic security risks and exposed secrets.
class SecurityAnalyzer implements Analyzer {
  /// Creates a security analyzer backed by [scanner].
  SecurityAnalyzer([this.scanner]);

  /// Scanner used to inspect project files.
  final FileScanner? scanner;

  /// Report section title for security checks.
  @override
  String get name => 'SECURITY AUDIT';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    final issues = <Issue>[];
    final patterns = [
      RegExp(r'''(api[_-]?key|secret|password)\s*[:=]\s*["'][^"']+["']''',
          caseSensitive: false),
      RegExp(r'AIza[0-9A-Za-z_-]{20,}')
    ];
    for (final file in context.scanner.allFiles(context).where((file) =>
        file.path.endsWith('.dart') ||
        file.path.endsWith('.yaml') ||
        file.path.endsWith('.json'))) {
      final text = file.readAsStringSync();
      if (patterns.any((pattern) => pattern.hasMatch(text))) {
        issues.add(Issue(
            severity: Severity.critical,
            problem: 'Possible hardcoded credential.',
            reason: 'Credentials in source can be extracted and abused.',
            files: [file.path],
            recommendedFix:
                'Rotate the credential and load it through a secure runtime configuration.',
            priority: 'Immediate'));
      }
    }
    return AnalyzerResult(
        analyzer: name,
        summary: 'Credential, Firebase, and sensitive configuration scan.',
        issues: issues);
  }
}
