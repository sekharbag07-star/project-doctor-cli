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

  test('registry lazily creates analyzers and exposes metadata', () {
    var creations = 0;
    final registry = AnalyzerRegistry();
    registry.registerFactory(
      AnalyzerMetadata(
        id: 'lazy',
        displayName: 'Lazy',
        description: 'A lazy analyzer.',
        category: AnalyzerCategory.other,
        supportedProjectTypes: const [ProjectType.dart],
        estimatedDuration: const Duration(seconds: 1),
        enabledByDefault: false,
      ),
      () {
        creations++;
        return _DelayedAnalyzer(() {}, () {});
      },
    );
    expect(creations, 0);
    expect(registry.find('lazy')!.metadata.enabledByDefault, isFalse);
    expect(registry.find('lazy')!.metadata.supportedProjectTypes,
        [ProjectType.dart]);
    expect(registry.analyzers.toList(), hasLength(1));
    expect(creations, 1);
  });

  test('legacy registry registration receives fallback metadata', () {
    final registry = AnalyzerRegistry();
    registry.register(_FailingAnalyzer());
    final metadata = registry.registrations.single.metadata;
    expect(metadata.id, 'failure');
    expect(metadata.displayName, 'Failure');
    expect(metadata.category, AnalyzerCategory.other);
    expect(metadata.enabledByDefault, isTrue);
  });

  test('Doctor.fromRegistry preserves registry analyzer order', () async {
    final directory =
        await Directory.systemTemp.createTemp('project_doctor_registry');
    addTearDown(() => directory.delete(recursive: true));
    final registry = AnalyzerRegistry();
    registry.registerFactory(
      AnalyzerMetadata(
        id: 'first',
        displayName: 'First',
        description: 'First analyzer.',
        category: AnalyzerCategory.other,
        supportedProjectTypes: const [ProjectType.dart],
      ),
      () => _NamedAnalyzer('First'),
    );
    registry.registerFactory(
      AnalyzerMetadata(
        id: 'second',
        displayName: 'Second',
        description: 'Second analyzer.',
        category: AnalyzerCategory.other,
        supportedProjectTypes: const [ProjectType.dart],
      ),
      () => _NamedAnalyzer('Second'),
    );
    final report =
        await Doctor.fromRegistry(registry, ReportBuilder(ScoreCalculator()))
            .run(directory);
    final contents = report.readAsStringSync();
    expect(contents.indexOf('First'), lessThan(contents.indexOf('Second')));
  });

  test('project type detection distinguishes Flutter, Dart, and unknown',
      () async {
    final flutter =
        await Directory.systemTemp.createTemp('project_doctor_flutter');
    final dart = await Directory.systemTemp.createTemp('project_doctor_dart');
    final unknown =
        await Directory.systemTemp.createTemp('project_doctor_unknown');
    addTearDown(() async {
      await flutter.delete(recursive: true);
      await dart.delete(recursive: true);
      await unknown.delete(recursive: true);
    });
    await File('${flutter.path}/pubspec.yaml')
        .writeAsString('dependencies:\n  flutter:\n    sdk: flutter\n');
    await File('${dart.path}/pubspec.yaml').writeAsString('name: sample\n');
    expect(detectProjectType(flutter), ProjectType.flutter);
    expect(detectProjectType(dart), ProjectType.dart);
    expect(detectProjectType(unknown), ProjectType.unknown);
  });

  test('context factory injects shared services and loads configuration',
      () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_context');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/pubspec.yaml')
        .writeAsString('name: context_test\n');
    await File('${root.path}/.project_doctor.yaml')
        .writeAsString('max_concurrent_analyzers: 2\n');
    final logger = _TestLogger();
    final scanner = FileScanner();
    final cache = MemoryCacheManager();
    final clock = _FixedClock(DateTime.utc(2026, 1, 1));
    final context = await ProjectContextFactory(
      environmentProvider: _TestEnvironmentProvider(),
      gitProvider: _TestGitProvider(),
      sdkProvider: _TestSdkProvider(),
      projectInfoProvider: _TestProjectInfoProvider(),
    ).create(root,
        logger: logger, scanner: scanner, cache: cache, clock: clock);
    expect(context.logger, same(logger));
    expect(context.scanner, same(scanner));
    expect(context.cache, same(cache));
    expect(context.clock, same(clock));
    expect(context.configuration.maxConcurrentAnalyzers, 2);
    expect(context.workingDirectory.path, root.path);
    expect(context.projectType, ProjectType.dart);
    expect(context.environment.tools['dart'], 'test');
  });

  test('Doctor passes the same context instance to every analyzer', () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_shared_context');
    addTearDown(() => root.delete(recursive: true));
    final first = _ContextAnalyzer();
    final second = _ContextAnalyzer();
    final factory = ProjectContextFactory(
      environmentProvider: _TestEnvironmentProvider(),
      gitProvider: _TestGitProvider(),
      sdkProvider: _TestSdkProvider(),
      projectInfoProvider: _TestProjectInfoProvider(),
    );
    await Doctor([first, second], ReportBuilder(ScoreCalculator()),
            contextFactory: factory)
        .run(root);
    expect(first.context, same(second.context));
  });

  test('context information collections are immutable', () {
    final environment = EnvironmentInfo({'dart': 'test'});
    final metadata = AnalyzerMetadata(
      id: 'test',
      displayName: 'Test',
      description: 'Test metadata.',
      category: AnalyzerCategory.other,
      supportedProjectTypes: const [ProjectType.dart],
    );
    expect(() => environment.tools['dart'] = 'changed', throwsUnsupportedError);
    expect(() => metadata.supportedProjectTypes.add(ProjectType.flutter),
        throwsUnsupportedError);
  });

  test('scanner streams files with ignore and extension filters', () async {
    final root = await Directory.systemTemp.createTemp('project_doctor_scan');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/lib').create();
    await Directory('${root.path}/ignored').create();
    await Directory('${root.path}/.hidden').create();
    await File('${root.path}/.gitignore').writeAsString('ignored/\n');
    await File('${root.path}/.project_doctor.yaml')
        .writeAsString('ignore:\n  - config_skip/**\n');
    await File('${root.path}/lib/main.dart').writeAsString('void main() {}');
    await File('${root.path}/lib/readme.txt').writeAsString('text');
    await File('${root.path}/ignored/skip.dart').writeAsString('skip');
    await File('${root.path}/.hidden/secret.dart').writeAsString('hidden');
    final configSkip = await Directory('${root.path}/config_skip').create();
    await File('${configSkip.path}/skip.dart').writeAsString('skip');

    final context = ProjectContext(
        root: root, configuration: DoctorConfiguration.load(root));
    final scanner = FileScanner();
    final result = scanner.scanResult(context,
        filter: const ScanFilter(extensions: {'.dart'}, includeHidden: false));
    final entities = await result.stream.toList();
    final paths = entities.map((entity) => entity.path).toList();
    expect(paths, contains(endsWith('main.dart')));
    expect(paths, isNot(contains(endsWith('readme.txt'))));
    expect(paths, isNot(contains(endsWith('skip.dart'))));
    expect(result.statistics.filesEmitted, 1);
    expect(result.statistics.directoriesVisited, greaterThanOrEqualTo(2));
  });

  test('scanner reports progress and handles cancellation', () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_scan_progress');
    addTearDown(() => root.delete(recursive: true));
    for (var index = 0; index < 100; index++) {
      await File('${root.path}/file_$index.txt').writeAsString('$index');
    }
    final token = _TestCancellationToken();
    final context = ProjectContext(root: root, cancellationToken: token);
    final progress = <String>[];
    final scanner = FileScanner();
    final result =
        scanner.scanResult(context, onProgress: (entity, statistics) {
      progress.add(entity.path);
      if (progress.length == 3) token.cancel();
    });
    await result.stream.toList();
    expect(progress.length, 3);
    expect(result.statistics.filesEmitted, 3);
  });

  test('scanner skips symbolic links when supported', () async {
    final root =
        await Directory.systemTemp.createTemp('project_doctor_scan_link');
    addTearDown(() => root.delete(recursive: true));
    final target =
        await File('${root.path}/target.txt').writeAsString('target');
    final link = Link('${root.path}/link.txt');
    try {
      await link.create(target.path);
    } on FileSystemException {
      return;
    }
    final result = FileScanner().scanResult(ProjectContext(root: root));
    final paths = (await result.stream.toList()).map((entity) => entity.path);
    expect(paths, contains(endsWith('target.txt')));
    expect(paths, isNot(contains(endsWith('link.txt'))));
    expect(result.statistics.symbolicLinksSkipped, 1);
  });

  test('path normalizer provides stable cross-platform paths', () {
    const normalizer = DefaultPathNormalizer();
    expect(normalizer.normalize(r'C:\workspace\lib\..\test\file.dart'),
        'C:/workspace/test/file.dart');
    expect(normalizer.normalize('./lib//main.dart'), 'lib/main.dart');
    expect(normalizer.normalize('/workspace/./lib/../test'), '/workspace/test');
    final matcher = IgnoreMatcher(['ignored\\**'], normalizer: normalizer);
    expect(matcher.matches('ignored/cache/file.txt'), isTrue);
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

class _NamedAnalyzer implements Analyzer {
  _NamedAnalyzer(this.name);

  @override
  final String name;

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async =>
      AnalyzerResult(analyzer: name, summary: 'ok');
}

class _ContextAnalyzer implements Analyzer {
  ProjectContext? context;

  @override
  String get name => 'Context';

  @override
  Future<AnalyzerResult> analyze(ProjectContext context) async {
    this.context = context;
    return const AnalyzerResult(analyzer: 'Context', summary: 'ok');
  }
}

class _TestEnvironmentProvider implements EnvironmentProvider {
  @override
  Future<EnvironmentInfo> load(Directory root, CommandRunner runner) async =>
      EnvironmentInfo({'dart': 'test'});
}

class _TestGitProvider implements GitProvider {
  @override
  Future<GitInfo> load(Directory root, CommandRunner runner) async =>
      const GitInfo(available: true, branch: 'test');
}

class _TestSdkProvider implements SdkProvider {
  @override
  Future<SdkInfo> load(Directory root, CommandRunner runner) async =>
      const SdkInfo(dartVersion: 'test');
}

class _TestProjectInfoProvider implements ProjectInfoProvider {
  @override
  Future<ProjectInfo> load(Directory root) async =>
      const ProjectInfo(name: 'test');
}

class _FixedClock implements Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _TestLogger implements LoggerService {
  @override
  void debug(String message) {}

  @override
  void error(String message) {}

  @override
  void info(String message) {}

  @override
  void trace(String message) {}

  @override
  void warning(String message) {}
}

class _TestCancellationToken implements CancellationToken {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  @override
  bool get isCancelled => _cancelled;
}
