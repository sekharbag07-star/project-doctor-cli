// Core behavior tests for scoring, orchestration, and report generation.

import 'dart:io';
import 'package:project_doctor_cli/project_doctor_cli.dart';
import 'package:test/test.dart';

/// Registers the core behavior test cases.
void main() {
  test('command runner captures output and caches identical commands',
      () async {
    final runner = CommandRunner();
    final first = await runner.run(
      Platform.resolvedExecutable,
      ['--version'],
      workingDirectory: Directory.current.path,
    );
    final second = await runner.run(
      Platform.resolvedExecutable,
      ['--version'],
      workingDirectory: Directory.current.path,
    );
    expect(first.success, isTrue);
    expect(first.command, Platform.resolvedExecutable);
    expect(first.duration, isNotNull);
    expect(identical(first, second), isTrue);
  });

  test('command runner reports graceful failures', () async {
    final result = await CommandRunner().run(
      'project-doctor-command-that-does-not-exist',
      const [],
      workingDirectory: Directory.current.path,
    );
    expect(result.success, isFalse);
    expect(result.stderr, isNotEmpty);
  });

  test('command runner terminates commands that exceed their timeout',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('project_doctor_timeout');
    addTearDown(() => directory.delete(recursive: true));
    final script = File('${directory.path}/sleep.dart');
    await script.writeAsString('''
import 'dart:async';
Future<void> main() async => Future<void>.delayed(const Duration(seconds: 2));
''');
    final result = await CommandRunner().run(
      Platform.resolvedExecutable,
      ['run', script.path],
      workingDirectory: directory.path,
      timeout: const Duration(milliseconds: 50),
      cache: false,
    );
    expect(result.timedOut, isTrue);
    expect(result.success, isFalse);
  });

  test('score calculator averages analyzer scores', () {
    final score = ScoreCalculator().calculate([
      const AnalyzerResult(analyzer: 'a', summary: 'ok'),
      const AnalyzerResult(analyzer: 'b', summary: 'ok', issues: [
        Issue(
            severity: Severity.high,
            problem: 'p',
            reason: 'r',
            files: [],
            recommendedFix: 'f',
            priority: 'now')
      ]),
    ]);
    expect(score, 93);
  });

  test('doctor continues after analyzer failure and writes one report',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('project_doctor_test');
    addTearDown(() => directory.delete(recursive: true));
    final doctor =
        Doctor([_FailingAnalyzer()], ReportBuilder(ScoreCalculator()));
    final report = await doctor.run(directory);
    expect(report.existsSync(), isTrue);
    expect(report.path, contains('project_report_'));
    expect(report.readAsStringSync(), contains('Analyzer failed'));
  });

  test('doctor limits analyzer concurrency from configuration', () async {
    final directory =
        await Directory.systemTemp.createTemp('project_doctor_pool');
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/.project_doctor.yaml')
        .writeAsString('max_concurrent_analyzers: 2\n');
    var active = 0;
    var peak = 0;
    final analyzers = List<Analyzer>.generate(
        5,
        (_) => _DelayedAnalyzer(() {
              active++;
              if (active > peak) peak = active;
            }, () => active--));
    await Doctor(analyzers, ReportBuilder(ScoreCalculator())).run(directory);
    expect(peak, 2);
  });

  test('weighted score uses built-in analyzer weights', () {
    final score = ScoreCalculator().calculate(const [
      AnalyzerResult(analyzer: 'SECURITY AUDIT', summary: 'ok', issues: [
        Issue(
            severity: Severity.high,
            problem: 'p',
            reason: 'r',
            files: [],
            recommendedFix: 'f',
            priority: 'now')
      ]),
      AnalyzerResult(analyzer: 'ARCHITECTURE AUDIT', summary: 'ok'),
    ]);
    expect(score, 93);
  });
}

class _FailingAnalyzer implements Analyzer {
  @override
  String get name => 'Failure';
  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async =>
      throw StateError('boom');
}

class _DelayedAnalyzer implements Analyzer {
  _DelayedAnalyzer(this.onStart, this.onFinish);

  final void Function() onStart;
  final void Function() onFinish;

  @override
  String get name => 'Delayed';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    onStart();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    onFinish();
    return const AnalyzerResult(analyzer: 'Delayed', summary: 'ok');
  }
}
