import 'dart:io';

/// Parsed command-line settings for a project doctor run.
class CliOptions {
  /// Creates immutable command-line settings.
  const CliOptions(
      {required this.projectPath,
      required this.outputDirectory,
      this.verbose = false,
      this.quiet = false,
      this.noColor = false,
      this.showHelp = false,
      this.showVersion = false});

  /// Project directory to audit.
  final Directory projectPath;

  /// Directory where the generated report is written.
  final Directory outputDirectory;

  /// Enables diagnostic logging.
  final bool verbose;

  /// Suppresses informational logging.
  final bool quiet;

  /// Disables terminal color output.
  final bool noColor;

  /// Whether help text was requested.
  final bool showHelp;

  /// Whether the tool version was requested.
  final bool showVersion;

  /// Usage text printed for the command-line interface.
  static const usage = '''Project Doctor CLI v1.0.0

Audit a Dart or Flutter project and write one deterministic text report.

Usage:
  dart run bin/project_doctor.dart [options]

Options:
  -h, --help             Show this help message.
      --version          Show the tool version.
      --project <path>   Project directory to audit (default: current directory).
      --output <path>    Report directory (default: <project>/reports).
      --verbose          Enable debug logging.
      --quiet            Suppress informational logging.
      --no-color         Disable colored terminal output.
''';

  /// Parses command-line arguments, optionally using [current] as the base directory.
  static CliOptions parse(List<String> arguments, {Directory? current}) {
    var project = current ?? Directory.current;
    Directory? output;
    var verbose = false;
    var quiet = false;
    var noColor = false;
    var help = false;
    var version = false;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      String value() => index + 1 < arguments.length ? arguments[++index] : '';
      switch (argument) {
        case '-h':
        case '--help':
          help = true;
        case '--version':
          version = true;
        case '--verbose':
          verbose = true;
        case '--quiet':
          quiet = true;
        case '--no-color':
          noColor = true;
        case '--project':
          project = Directory(value());
        case '--output':
          output = Directory(value());
        default:
          throw FormatException('Unknown option: $argument');
      }
    }
    return CliOptions(
        projectPath: project.absolute,
        outputDirectory: (output ??
                Directory('${project.path}${Platform.pathSeparator}reports'))
            .absolute,
        verbose: verbose,
        quiet: quiet,
        noColor: noColor,
        showHelp: help,
        showVersion: version);
  }
}
