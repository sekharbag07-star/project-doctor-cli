import 'dart:async';
import 'dart:collection';
import 'dart:io';

import '../core/project_context.dart';
import 'path_normalizer.dart';

/// Read-only file scanning contract used by analyzers.
abstract interface class ProjectFileScanner {
  /// Lazily traverses [context] and emits matching filesystem entities.
  Stream<FileSystemEntity> scan(ProjectContext context,
      {ScanFilter filter = const ScanFilter(),
      void Function(FileSystemEntity entity, ScanStatistics statistics)?
          onProgress});
}

/// Controls which entities a scan emits.
class ScanFilter {
  /// Creates a filter for [extensions] and directory/file options.
  const ScanFilter({
    this.extensions = const <String>{},
    this.includeHidden = true,
    this.includeSymbolicLinks = false,
    this.excludedDirectories = const <String>{},
  });

  /// Lowercase extensions to include, such as `.dart`; empty means all.
  final Set<String> extensions;

  /// Whether hidden files and directories are eligible for scanning.
  final bool includeHidden;

  /// Whether symbolic links should be emitted instead of skipped.
  final bool includeSymbolicLinks;

  /// Additional directory names excluded from traversal.
  final Set<String> excludedDirectories;

  /// Returns whether [entity] is accepted by this filter.
  bool matches(FileSystemEntity entity, String relativePath) {
    final name = _basename(relativePath);
    if (!includeHidden && name.startsWith('.')) return false;
    if (entity is! File) return true;
    if (extensions.isEmpty) return true;
    final lowerPath = entity.path.toLowerCase();
    return extensions.any((extension) =>
        lowerPath.endsWith(extension.toLowerCase()) ||
        lowerPath.endsWith('.${extension.toLowerCase()}'));
  }
}

/// Compiled ignore rules from defaults, configuration, and `.gitignore`.
class IgnoreMatcher {
  /// Creates a matcher from glob-like [patterns].
  IgnoreMatcher(Iterable<String> patterns,
      {PathNormalizer normalizer = const DefaultPathNormalizer()})
      : _normalizer = normalizer,
        _rules = patterns
            .map(normalizer.normalize)
            .map(_normalizePattern)
            .where((pattern) => pattern.isNotEmpty)
            .map(_IgnoreRule.new)
            .toList(growable: false);

  final List<_IgnoreRule> _rules;
  final PathNormalizer _normalizer;

  /// Returns whether [relativePath] should be ignored.
  bool matches(String relativePath, {bool isDirectory = false}) {
    final normalized = _normalizer.normalize(relativePath);
    var ignored = false;
    for (final rule in _rules) {
      if (rule.matches(normalized, isDirectory: isDirectory)) {
        ignored = !rule.negated;
      }
    }
    return ignored;
  }

  static String _normalizePattern(String pattern) {
    var normalized = pattern.trim().replaceAll('\\', '/');
    if (normalized.startsWith('#') || normalized.isEmpty) return '';
    if (normalized.startsWith('!')) {
      normalized =
          '!${normalized.substring(1).replaceFirst(RegExp(r'^/+'), '')}';
    } else {
      normalized = normalized.replaceFirst(RegExp(r'^/+'), '');
    }
    return normalized;
  }
}

/// Counts entities encountered during one scan.
class ScanStatistics {
  /// Number of filesystem entities emitted.
  int emitted = 0;

  /// Number of directories visited.
  int directoriesVisited = 0;

  /// Number of files emitted.
  int filesEmitted = 0;

  /// Number of directories excluded by ignore or filter rules.
  int directoriesIgnored = 0;

  /// Number of symbolic links skipped.
  int symbolicLinksSkipped = 0;

  /// Number of hidden entities skipped.
  int hiddenSkipped = 0;
}

/// A lazy scan stream and the statistics it updates as it is consumed.
class ScanResult {
  /// Creates a scan result from [stream] and mutable [statistics].
  const ScanResult({required this.stream, required this.statistics});

  /// Lazy filesystem entity stream.
  final Stream<FileSystemEntity> stream;

  /// Statistics updated during stream consumption.
  final ScanStatistics statistics;

  /// Alias for [stream] for callers that prefer entity terminology.
  Stream<FileSystemEntity> get entities => stream;
}

/// Recursively discovers project files without materializing the repository.
class FileScanner implements ProjectFileScanner {
  /// Directory names excluded from every scan by default.
  static const defaultIgnored = {
    '.dart_tool',
    '.git',
    'build',
    '.idea',
    '.vscode',
    '.gradle',
    'node_modules',
    'coverage',
  };

  final Map<String, IgnoreMatcher> _ignoreCache = {};

  /// Normalizer used for relative paths and ignore matching.
  final PathNormalizer pathNormalizer;

  /// Creates a streaming scanner.
  FileScanner({this.pathNormalizer = const DefaultPathNormalizer()});

  /// Creates a scan result whose stream starts traversal on listen.
  ScanResult scanResult(ProjectContext context,
      {ScanFilter filter = const ScanFilter(),
      void Function(FileSystemEntity entity, ScanStatistics statistics)?
          onProgress}) {
    final statistics = ScanStatistics();
    return ScanResult(
      stream: _scan(context, filter, statistics, onProgress),
      statistics: statistics,
    );
  }

  /// Lazily traverses [context] and emits matching filesystem entities.
  @override
  Stream<FileSystemEntity> scan(ProjectContext context,
          {ScanFilter filter = const ScanFilter(),
          void Function(FileSystemEntity entity, ScanStatistics statistics)?
              onProgress}) =>
      scanResult(context, filter: filter, onProgress: onProgress).stream;

  Stream<FileSystemEntity> _scan(
      ProjectContext context,
      ScanFilter filter,
      ScanStatistics statistics,
      void Function(FileSystemEntity entity, ScanStatistics statistics)?
          onProgress) async* {
    final matcher = _matcher(context);
    final pending = Queue<Directory>()..add(context.root);
    while (pending.isNotEmpty) {
      if (context.cancellationToken.isCancelled) return;
      final directory = pending.removeFirst();
      statistics.directoriesVisited++;
      await for (final entity in directory.list(followLinks: false)) {
        if (context.cancellationToken.isCancelled) return;
        final relative = _relativePath(context, entity.path);
        final isDirectory = entity is Directory;
        final name = _basename(relative);
        if (!filter.includeHidden && name.startsWith('.')) {
          statistics.hiddenSkipped++;
          if (isDirectory) statistics.directoriesIgnored++;
          continue;
        }
        if (entity is Link) {
          statistics.symbolicLinksSkipped++;
          if (filter.includeSymbolicLinks) {
            statistics.emitted++;
            yield entity;
            onProgress?.call(entity, statistics);
          }
          continue;
        }
        if (isDirectory) {
          if (defaultIgnored.contains(name) ||
              filter.excludedDirectories.contains(name) ||
              matcher.matches(relative, isDirectory: true)) {
            statistics.directoriesIgnored++;
            continue;
          }
          pending.add(entity);
        }
        if (!filter.matches(entity, relative) ||
            matcher.matches(relative, isDirectory: false)) {
          continue;
        }
        statistics.emitted++;
        if (entity is File) statistics.filesEmitted++;
        yield entity;
        onProgress?.call(entity, statistics);
      }
    }
  }

  IgnoreMatcher _matcher(ProjectContext context) {
    final key =
        '${context.path}|${context.configuration.ignore.join('\u0000')}';
    final cached = _ignoreCache[key];
    if (cached != null) return cached;
    final patterns = <String>[...context.configuration.ignore];
    final gitignore =
        File('${context.path}${Platform.pathSeparator}.gitignore');
    if (gitignore.existsSync()) patterns.addAll(gitignore.readAsLinesSync());
    final matcher = IgnoreMatcher(patterns, normalizer: pathNormalizer);
    _ignoreCache[key] = matcher;
    return matcher;
  }

  String _relativePath(ProjectContext context, String path) {
    final normalizedRoot = pathNormalizer.normalize(context.path);
    final normalizedPath = pathNormalizer.normalize(path);
    return normalizedPath
        .substring(normalizedRoot.length)
        .replaceFirst(RegExp(r'^/'), '');
  }
}

class _IgnoreRule {
  _IgnoreRule(String pattern)
      : negated = pattern.startsWith('!'),
        directoryOnly = pattern.endsWith('/'),
        _hasSlash = pattern.replaceFirst(RegExp(r'^!'), '').contains('/'),
        _regex = RegExp(_buildRegex(pattern));

  final bool negated;
  final bool directoryOnly;
  final bool _hasSlash;
  final RegExp _regex;

  bool matches(String path, {required bool isDirectory}) {
    if (directoryOnly && !isDirectory) return false;
    final candidate = _hasSlash ? path : _basename(path);
    return _regex.hasMatch(candidate);
  }

  static String _buildRegex(String pattern) {
    final directoryOnly = pattern.endsWith('/');
    final value = pattern.startsWith('!')
        ? pattern.substring(1).replaceFirst(RegExp(r'/$'), '')
        : pattern.replaceFirst(RegExp(r'/$'), '');
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final character = value[index];
      if (character == '/' &&
          index + 2 < value.length &&
          value[index + 1] == '*' &&
          value[index + 2] == '*') {
        buffer.write(r'(?:/.*)?');
        index += 2;
        continue;
      }
      if (character == '*') {
        final nextIsStar = index + 1 < value.length && value[index + 1] == '*';
        if (nextIsStar) {
          buffer.write('.*');
          index++;
        } else {
          buffer.write('[^/]*');
        }
      } else {
        buffer.write(RegExp.escape(character));
      }
    }
    return '^${buffer.toString()}${directoryOnly ? r'(?:/.*)?' : r'$'}';
  }
}

String _basename(String path) => path.split('/').last;
