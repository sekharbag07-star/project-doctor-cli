import 'dart:io';

import 'package:project_doctor_cli/project_doctor_cli.dart';
import 'package:test/test.dart';

void main() {
  test('ReportBuilder produces immutable ordered documents', () {
    final builder = ReportBuilder(ScoreCalculator());
    final document = builder.build(
      results: const [
        AnalyzerResult(analyzer: 'SECOND', summary: 'second'),
        AnalyzerResult(analyzer: 'FIRST', summary: 'first'),
      ],
      startedAt: DateTime.utc(2026, 1, 1),
      projectPath: r'C:\workspace\sample',
      totalDuration: const Duration(milliseconds: 42),
    );

    expect(document.metadata.projectName, 'sample');
    expect(
        document.sections.map((section) => section.title), ['SECOND', 'FIRST']);
    expect(() => document.sections.add(document.sections.first),
        throwsUnsupportedError);
    expect(() => document.recommendations.add('new'), throwsUnsupportedError);
  });

  test('SectionRegistry supports extension sections and automatic TOC', () {
    final registry = SectionRegistry.standard();
    registry.register((result, order) => ReportSection(
          id: 'extension-${result.analyzer}',
          title: 'Extension ${result.analyzer}',
          order: order,
          severity: Severity.info,
          body: 'extension',
        ));
    final sections = registry.build(const [
      AnalyzerResult(analyzer: 'A', summary: 'a'),
    ]);
    expect(sections.map((section) => section.title), ['A', 'Extension A']);
    expect(
        TocGenerator().generate(sections).toList(), ['1. A', '2. Extension A']);
  });

  test('RecommendationBuilder sorts high before medium and low issues', () {
    final recommendations = RecommendationBuilder().build(const [
      AnalyzerResult(analyzer: 'x', summary: 'x', issues: [
        Issue(
            severity: Severity.low,
            problem: 'low',
            reason: 'reason',
            files: [],
            recommendedFix: 'low fix',
            priority: 'Later'),
        Issue(
            severity: Severity.high,
            problem: 'high',
            reason: 'reason',
            files: [],
            recommendedFix: 'high fix',
            priority: 'Now'),
        Issue(
            severity: Severity.medium,
            problem: 'medium',
            reason: 'reason',
            files: [],
            recommendedFix: 'medium fix',
            priority: 'Soon'),
      ])
    ]);
    expect(recommendations,
        ['[Now] high fix', '[Soon] medium fix', '[Later] low fix']);
  });

  test('formatters provide tables, sections, scores, and wrapping', () {
    expect(
        TableFormatter().format(const [
          MapEntry('Name', 'Status'),
          MapEntry('Dart', 'PASS')
        ]).toList(),
        ['Name  Status', 'Dart  PASS']);
    expect(ScoreFormatter().format(80), '████████░░ 80%');
    expect(TextFormatter().wrap('one two three', width: 7).toList(),
        ['one two', 'three']);
    final buffer = StringBuffer();
    SectionFormatter().write(
        buffer,
        const ReportSection(
            id: 'id',
            title: 'TITLE',
            order: 0,
            severity: Severity.info,
            body: 'body'));
    expect(buffer.toString(), contains('TITLE'));
  });

  test('ReportWriter streams UTF-8 report output', () async {
    final directory =
        await Directory.systemTemp.createTemp('project_doctor_report_writer');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/reports/report.txt');
    final document = ReportDocument(
      metadata: ReportMetadata(
        projectName: 'sample',
        generatedAt: DateTime.utc(2026, 1, 1),
        doctorVersion: '1.0.0',
        projectLocation: directory.path,
        executionDuration: Duration.zero,
        operatingSystem: 'test',
      ),
      sections: [
        const ReportSection(
            id: 'unicode',
            title: 'UNICODE',
            order: 0,
            severity: Severity.info,
            body: 'café'),
      ],
      recommendations: const [],
      healthScore: 100,
    );
    await const ReportWriter().write(file: file, document: document);
    expect(await file.readAsString(), contains('café'));
  });

  test('ReportWriter handles many sections without report buffer assembly',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('project_doctor_large_report');
    addTearDown(() => directory.delete(recursive: true));
    final sections = List<ReportSection>.generate(
      1000,
      (index) => ReportSection(
        id: 'section-$index',
        title: 'SECTION $index',
        order: index,
        severity: Severity.info,
        body: 'line $index',
      ),
    );
    final document = ReportDocument(
      metadata: ReportMetadata(
        projectName: 'large',
        generatedAt: DateTime.utc(2026, 1, 1),
        doctorVersion: '1.0.0',
        projectLocation: directory.path,
        executionDuration: Duration.zero,
        operatingSystem: 'test',
      ),
      sections: sections,
      recommendations: const [],
      healthScore: 100,
    );
    final file = File('${directory.path}/large.txt');
    await const ReportWriter().write(file: file, document: document);
    expect((await file.readAsLines()).length, greaterThan(3000));
  });
}
