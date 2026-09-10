import 'dart:io';

/// Configures thresholds and exclusions for project analysis.
class DoctorConfiguration {
  /// Creates configuration values using conservative audit defaults.
  const DoctorConfiguration(
      {this.ignore = const [],
      this.maxFileSizeMb = 5,
      this.maxMethodLines = 100,
      this.maxWidgetLines = 250,
      this.allowPrint = false,
      this.allowDebugPrint = false,
      this.maxConcurrentAnalyzers = 4});

  /// Glob-like relative paths excluded from file scanning.
  final List<String> ignore;

  /// Maximum permitted source-file size in megabytes.
  final int maxFileSizeMb;

  /// Maximum method length threshold.
  final int maxMethodLines;

  /// Maximum widget/file line threshold used by metrics checks.
  final int maxWidgetLines;

  /// Whether ordinary `print` calls are allowed.
  final bool allowPrint;

  /// Whether Flutter `debugPrint` calls are allowed.
  final bool allowDebugPrint;

  /// Maximum number of analyzers allowed to run at once.
  final int maxConcurrentAnalyzers;

  /// Loads `.project_doctor.yaml` from [root], or returns default values.
  static DoctorConfiguration load(Directory root) {
    final file =
        File('${root.path}${Platform.pathSeparator}.project_doctor.yaml');
    if (!file.existsSync()) return const DoctorConfiguration();
    final ignore = <String>[];
    var maxFileSizeMb = 5;
    var maxMethodLines = 100;
    var maxWidgetLines = 250;
    var allowPrint = false;
    var allowDebugPrint = false;
    var maxConcurrentAnalyzers = 4;
    var inIgnore = false;
    for (final rawLine in file.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line == 'ignore:') {
        inIgnore = true;
        continue;
      }
      if (inIgnore && line.startsWith('- ')) {
        ignore.add(line.substring(2).trim());
        continue;
      }
      inIgnore = false;
      final separator = line.indexOf(':');
      if (separator < 0) continue;
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      switch (key) {
        case 'max_file_size_mb':
          maxFileSizeMb = int.tryParse(value) ?? maxFileSizeMb;
        case 'max_method_lines':
          maxMethodLines = int.tryParse(value) ?? maxMethodLines;
        case 'max_widget_lines':
          maxWidgetLines = int.tryParse(value) ?? maxWidgetLines;
        case 'allow_print':
          allowPrint = value.toLowerCase() == 'true';
        case 'allow_debug_print':
          allowDebugPrint = value.toLowerCase() == 'true';
        case 'max_concurrent_analyzers':
          maxConcurrentAnalyzers =
              int.tryParse(value) ?? maxConcurrentAnalyzers;
      }
    }
    return DoctorConfiguration(
        ignore: List.unmodifiable(ignore),
        maxFileSizeMb: maxFileSizeMb,
        maxMethodLines: maxMethodLines,
        maxWidgetLines: maxWidgetLines,
        allowPrint: allowPrint,
        allowDebugPrint: allowDebugPrint,
        maxConcurrentAnalyzers: maxConcurrentAnalyzers.clamp(1, 64));
  }
}
