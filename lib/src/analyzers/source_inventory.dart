import 'dart:io';

import '../core/project_context.dart';
import '../services/file_scanner.dart';
import '../services/path_normalizer.dart';

const _sourceInventoryCacheKey = 'phase5.sourceInventory';

/// Immutable normalized Dart source inventory shared by Phase 5 analyzers.
class SourceInventory {
  /// Creates an inventory from normalized paths and file contents.
  SourceInventory(Map<String, String> contents)
      : contents = Map.unmodifiable(contents);

  /// Normalized project-relative Dart paths and their source text.
  final Map<String, String> contents;
}

/// Loads and caches Dart source files once per audit context.
Future<SourceInventory> loadSourceInventory(ProjectContext context) async {
  final cached = context.cache.read(_sourceInventoryCacheKey);
  if (cached is Future<SourceInventory>) return cached;
  final future = _buildSourceInventory(context);
  context.cache.write(_sourceInventoryCacheKey, future);
  return future;
}

Future<SourceInventory> _buildSourceInventory(ProjectContext context) async {
  const normalizer = DefaultPathNormalizer();
  final root = normalizer.normalize(context.path);
  final contents = <String, String>{};
  await for (final entity in context.scanner
      .scan(context, filter: const ScanFilter(extensions: {'.dart'}))) {
    if (entity is! File) continue;
    final normalized = normalizer.normalize(entity.path);
    final relative =
        normalized.substring(root.length).replaceFirst(RegExp(r'^/'), '');
    contents[relative] = await entity.readAsString();
  }
  return SourceInventory(contents);
}
