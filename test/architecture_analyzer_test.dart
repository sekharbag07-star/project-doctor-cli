import 'dart:io';

import 'package:project_doctor_cli/project_doctor_cli.dart';
import 'package:test/test.dart';

void main() {
  test('dependency graph detects import cycles', () {
    final graph = DependencyGraph(
      const {'a.dart', 'b.dart', 'c.dart'},
      const [
        ImportEdge(source: 'a.dart', target: 'b.dart', uri: 'b.dart'),
        ImportEdge(source: 'b.dart', target: 'c.dart', uri: 'c.dart'),
        ImportEdge(source: 'c.dart', target: 'a.dart', uri: 'a.dart'),
      ],
    );
    expect(graph.cycles(), hasLength(1));
    expect(graph.cycles().single, containsAll(['a.dart', 'b.dart', 'c.dart']));
  });

  test('finding is immutable and converts to legacy issue', () {
    final finding = Finding(
      id: 'layer.violation',
      title: 'Invalid dependency',
      description: 'A layer boundary was crossed.',
      severity: Severity.high,
      category: 'architecture',
      priority: Priority.immediate,
      affectedFiles: const ['lib/a.dart'],
      recommendation: 'Reverse the dependency.',
    );
    expect(finding.toIssue().problem, 'Invalid dependency');
    expect(
        () => finding.affectedFiles.add('lib/b.dart'), throwsUnsupportedError);
  });

  test('import analyzer reports forbidden presentation infrastructure import',
      () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_architecture');
    addTearDown(() => root.delete(recursive: true));
    final source = Directory('${root.path}/lib/presentation')
      ..createSync(recursive: true);
    final target = Directory('${root.path}/lib/infrastructure')
      ..createSync(recursive: true);
    await File('${target.path}/database.dart')
        .writeAsString('class Database {}');
    await File('${source.path}/screen.dart').writeAsString(
        "import '../infrastructure/database.dart';\nclass Screen {}\n");
    final context = ProjectContext(root: root);
    final result = await ImportAnalyzer().analyze(context);
    expect(result.issues, isNotEmpty);
    expect(result.issues.single.severity, Severity.high);
  });

  test('project structure analyzer reports missing expected directories',
      () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_structure');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/lib').create();
    final result =
        await ProjectStructureAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues, isNotEmpty);
    expect(result.issues.map((issue) => issue.problem),
        contains('Expected directory is missing'));
  });

  test('architecture analyzer detects missing clean architecture layers',
      () async {
    final root = await Directory.systemTemp
        .createTemp('project_doctor_clean_architecture');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/lib/domain').create(recursive: true);
    await File('${root.path}/lib/domain/model.dart')
        .writeAsString('class Model {}');
    final result =
        await ArchitectureAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues.map((issue) => issue.problem),
        contains('Missing presentation layer'));
  });

  test('repository analyzer detects implementations without abstractions',
      () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_repository');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/lib/infrastructure').create(recursive: true);
    await File('${root.path}/lib/infrastructure/user_repository.dart')
        .writeAsString('class UserRepository implements UserStore {}');
    final result =
        await RepositoryAnalyzer().analyze(ProjectContext(root: root));
    expect(result.issues.map((issue) => issue.problem),
        contains('Repository implementation lacks abstraction'));
  });

  test('feature analyzer discovers feature files', () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_feature');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/lib/features/auth').create(recursive: true);
    await File('${root.path}/lib/features/auth/login.dart')
        .writeAsString('class Login {}');
    final result = await FeatureAnalyzer().analyze(ProjectContext(root: root));
    expect(result.data['Features'], '1');
    expect(result.data['auth'], '1 files');
  });
}
