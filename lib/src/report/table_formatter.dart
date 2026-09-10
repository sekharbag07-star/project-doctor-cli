/// Formats simple two-column ASCII tables.
class TableFormatter {
  /// Formats [rows] with a padded name column.
  Iterable<String> format(Iterable<MapEntry<String, String>> rows) sync* {
    final entries = rows.toList(growable: false);
    final width = entries.fold<int>(
        0,
        (current, entry) =>
            entry.key.length > current ? entry.key.length : current);
    for (final entry in entries) {
      yield '${entry.key.padRight(width + 2)}${entry.value}';
    }
  }
}
