import 'dart:io';
import '../core/project_context.dart';

/// Read-only file scanning contract used by analyzers.
abstract interface class ProjectFileScanner {
  /// Returns Dart source files beneath [context].
  Iterable<File> dartFiles(ProjectContext context);

  /// Returns all non-ignored files beneath [context].
  Iterable<File> allFiles(ProjectContext context);
}

/// Recursively discovers project files while honoring ignore rules.
class FileScanner implements ProjectFileScanner {
  /// Directory names excluded from every scan by default.
  static const defaultIgnored = {
    '.dart_tool',
    '.git',
    'build',
    '.idea',
    '.gradle',
    'node_modules'
  };
  final Map<String, List<File>> _cache = {};

  /// Returns cached Dart source files beneath [context].
  @override
  Iterable<File> dartFiles(ProjectContext context) =>
      _files(context).where((file) => file.path.endsWith('.dart'));

  /// Returns all non-ignored files beneath [context].
  @override
  Iterable<File> allFiles(ProjectContext context) => _files(context);

  List<File> _files(ProjectContext context) {
    final cached = _cache[context.path];
    if (cached != null) return cached;
    final files = <File>[];
    void visit(Directory directory) {
      final name = directory.path.split(RegExp(r'[/\\]')).last;
      if (defaultIgnored.contains(name) ||
          _matchesIgnored(context, directory.path)) {
        return;
      }
      for (final entity in directory.listSync(followLinks: false)) {
        if (entity is Directory) visit(entity);
        if (entity is File && !_matchesIgnored(context, entity.path)) {
          files.add(entity);
        }
      }
    }

    visit(context.root);
    _cache[context.path] = List.unmodifiable(files);
    return _cache[context.path]!;
  }

  bool _matchesIgnored(ProjectContext context, String path) {
    final relative = path
        .substring(context.path.length)
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/'), '');
    return context.configuration.ignore.any((pattern) {
      final regex = RegExp(
          '^${RegExp.escape(pattern).replaceAll(r'\*\*', '.*').replaceAll(r'\*', '[^/]*')}\$');
      return regex.hasMatch(relative);
    });
  }
}
