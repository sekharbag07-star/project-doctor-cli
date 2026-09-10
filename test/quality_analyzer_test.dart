import 'dart:io';

import 'package:project_doctor_cli/project_doctor_cli.dart';
import 'package:test/test.dart';

void main() {
  Future<Directory> fixture(String prefix) async {
    final root = await Directory.systemTemp.createTemp(prefix);
    addTearDown(() => root.delete(recursive: true));
    return root;
  }

  test('quality models are immutable and calculate debt units', () {
    const debt = TechnicalDebt(
        minutes: 120, priority: 'High', risk: 'High', impact: 'Quality');
    expect(debt.hours, 2);
    expect(debt.days, .25);
    final issue = CodeIssue(
      id: 'test',
      title: 'Issue',
      description: 'Description',
      severity: Severity.high,
      category: QualityCategory.style,
      issueType: IssueType.todo,
      locations: const [CodeLocation(file: 'lib/a.dart')],
      recommendation: const Recommendation(
          problem: 'p',
          reason: 'r',
          impact: 'i',
          suggestedFix: 'f',
          example: 'e',
          priority: 'High',
          estimatedMinutes: 10),
    );
    expect(() => issue.locations.add(const CodeLocation(file: 'x')),
        throwsUnsupportedError);
    expect(issue.toIssue().recommendedFix, 'f');
  });

  test('metrics engine reports complexity and source size', () {
    final metric = QualitySupport.metrics(
        'class A { void run() { if (true) { while (false) {} } } }', 3);
    expect(metric.linesOfCode, 1);
    expect(metric.dependencyCount, 3);
    expect(metric.cyclomaticComplexity, greaterThan(1));
    expect(metric.maintainabilityIndex, lessThanOrEqualTo(100));
  });

  test('duplicate analyzer finds repeated token windows', () async {
    final root = await fixture('project_doctor_duplicate');
    final code =
        'void shared() { final a = 1; final b = 2; final c = 3; return; }';
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/a.dart').writeAsString(code);
    await File('${root.path}/lib/b.dart').writeAsString(code);
    final result = await DuplicateCodeAnalyzer(minimumTokens: 5)
        .analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
    expect(result.issues.first.problem, 'Duplicate code detected');
  });

  test('complexity analyzer reports deeply branched source', () async {
    final root = await fixture('project_doctor_complexity');
    await Directory('${root.path}/lib').create();
    final branches = List.filled(20, 'if (value) {').join(' ');
    await File('${root.path}/lib/complex.dart')
        .writeAsString('void run(bool value) { $branches }');
    final result =
        await ComplexityAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
  });

  test('long method analyzer respects project threshold', () async {
    final root = await fixture('project_doctor_long_method');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/long.dart')
        .writeAsString(List.filled(250, 'final value = 1;').join('\n'));
    final result =
        await LongMethodAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
    expect(result.issues.first.severity, Severity.medium);
  });

  test('documentation analyzer reports low coverage', () async {
    final root = await fixture('project_doctor_docs');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/public.dart')
        .writeAsString('class A {}\nclass B {}\nclass C {}');
    final result =
        await DocumentationAnalyzer().analyze(ProjectContext(root: root));
    expect(result.data['Documentation'], isNotNull);
    expect(result.issues, isNotEmpty);
  });

  test('style analyzer tracks TODO markers', () async {
    final root = await fixture('project_doctor_style');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/todo.dart').writeAsString('// TODO: fix this');
    final result = await StyleAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
  });

  test('widget analyzer detects large Flutter source', () async {
    final root = await fixture('project_doctor_widget');
    await Directory('${root.path}/lib').create();
    final lines = List.filled(260, 'final value = 1;').join('\n');
    await File('${root.path}/lib/widget.dart')
        .writeAsString('class Widget extends StatelessWidget {\n$lines\n}');
    final result = await WidgetAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
  });

  test('naming analyzer detects lowercase class names', () async {
    final root = await fixture('project_doctor_naming');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/name.dart').writeAsString('class badName {}');
    final result = await NamingAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
  });

  test('API analyzer detects oversized signatures', () async {
    final root = await fixture('project_doctor_api');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/api.dart').writeAsString(
        'void run(${List.filled(30, 'String value').join(', ')}) {}');
    final result =
        await ApiDesignAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
  });

  test('SOLID analyzer produces dependency inversion findings', () async {
    final root = await fixture('project_doctor_solid');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/service.dart').writeAsString(
        'class Service { void run() { final value = new Concrete(); } }');
    final result = await SolidAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
  });

  test('maintainability analyzer reports aggregate metrics', () async {
    final root = await fixture('project_doctor_maintainability');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/code.dart').writeAsString('class Code {}');
    final result =
        await MaintainabilityAnalyzer().analyze(ProjectContext(root: root));
    expect(result.data['Maintainability Index'], isNotNull);
  });

  test('aggregate quality analyzer reports overall score', () async {
    final root = await fixture('project_doctor_quality_score');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/code.dart').writeAsString('class Code {}');
    final result = await QualityAnalyzer().analyze(ProjectContext(root: root));
    expect(result.data['Overall Score'], endsWith('/100'));
  });

  test('dead code analyzer detects private declarations', () async {
    final root = await fixture('project_doctor_dead');
    await Directory('${root.path}/lib').create();
    await File('${root.path}/lib/dead.dart').writeAsString('void _unused() {}');
    final result = await DeadCodeAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
  });

  test('technical debt exposes hours and days', () {
    const debt = TechnicalDebt(
        minutes: 480, priority: 'Normal', risk: 'Medium', impact: 'Quality');
    expect(debt.hours, 8);
    expect(debt.days, 1);
  });

  test('quality score model stores all dimensions', () {
    const score = QualityScore(
        maintainability: 80,
        complexity: 70,
        documentation: 60,
        codeQuality: 75,
        overall: 72);
    expect(score.overall, 72);
    expect(score.documentation, 60);
  });
}
