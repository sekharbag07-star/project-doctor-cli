/// Normalizes filesystem paths for cross-platform comparison and matching.
abstract interface class PathNormalizer {
  /// Returns a stable, separator-independent representation of [path].
  String normalize(String path);
}

/// Default lexical path normalizer used by the scanner.
class DefaultPathNormalizer implements PathNormalizer {
  /// Creates the default path normalizer.
  const DefaultPathNormalizer();

  @override
  String normalize(String path) {
    if (path.isEmpty) return path;
    final replaced = path.replaceAll('\\', '/');
    final absolute = replaced.startsWith('/');
    final drive = RegExp(r'^[A-Za-z]:').firstMatch(replaced)?.group(0);
    final segments = <String>[];
    for (final segment in replaced.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (segments.isNotEmpty && segments.last != '..') {
          segments.removeLast();
        } else if (!absolute && drive == null) {
          segments.add(segment);
        }
        continue;
      }
      segments.add(segment);
    }
    final prefix = absolute ? '/' : '';
    final normalized = '$prefix${segments.join('/')}';
    if (drive != null && normalized == drive) return '$drive/';
    return normalized.isEmpty && absolute ? '/' : normalized;
  }
}
