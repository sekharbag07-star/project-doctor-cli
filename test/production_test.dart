// Production-style tests for command-line option parsing.

import 'dart:io';
import 'package:project_doctor_cli/project_doctor_cli.dart';
import 'package:test/test.dart';

/// Registers production behavior test cases.
void main() {
  test('logger exposes all levels and quiet color controls', () {
    final logger = Logger(verbose: true, quiet: true, noColor: true);
    expect(LogLevel.values, contains(LogLevel.trace));
    expect(logger.verbose, isTrue);
    expect(logger.quiet, isTrue);
    expect(logger.noColor, isTrue);
    logger.trace('hidden in quiet mode');
  });

  test('CLI parses project, output, and logging flags', () {
    final options = CliOptions.parse([
      '--project',
      'app',
      '--output',
      'out',
      '--verbose',
      '--quiet',
      '--no-color'
    ], current: Directory('/workspace'));
    expect(options.projectPath.path, endsWith('app'));
    expect(options.outputDirectory.path, endsWith('out'));
    expect(options.verbose, isTrue);
    expect(options.quiet, isTrue);
    expect(options.noColor, isTrue);
  });

  test('configuration overrides defaults', () async {
    final root = await Directory.systemTemp.createTemp('project_doctor_config');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/.project_doctor.yaml').writeAsString('''
ignore:
  - build/**
max_file_size_mb: 9
max_method_lines: 40
max_widget_lines: 80
allow_print: true
allow_debug_print: true
max_concurrent_analyzers: 3
''');
    final config = DoctorConfiguration.load(root);
    expect(config.maxFileSizeMb, 9);
    expect(config.maxMethodLines, 40);
    expect(config.maxWidgetLines, 80);
    expect(config.allowPrint, isTrue);
    expect(config.maxConcurrentAnalyzers, 3);
  });

  test('report contains deterministic production sections', () async {
    final root = await Directory.systemTemp.createTemp('project_doctor_report');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/report.txt');
    await ReportBuilder(ScoreCalculator()).write(
        file: file,
        startedAt: DateTime.utc(2026, 1, 1),
        projectPath: '/example',
        version: '1.0.0',
        totalDuration: const Duration(milliseconds: 12),
        results: const [
          AnalyzerResult(analyzer: 'ENVIRONMENT', summary: 'ok')
        ]);
    final report = await file.readAsString();
    expect(report, contains('TABLE OF CONTENTS'));
    expect(report, contains('Total execution time: 12 ms'));
    expect(report, contains('FINAL HEALTH SCORE'));
  });
}
