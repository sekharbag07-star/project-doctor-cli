# Project Doctor CLI

Project Doctor CLI is a reusable, cross-platform Dart command-line auditor for Flutter and Dart projects. It produces one deterministic text report per run.

## Installation

Requires the latest stable Dart SDK. From this repository:

```bash
dart pub get
dart run bin/project_doctor.dart
```

## Usage

```bash
dart run bin/project_doctor.dart --project ./my_app --output ./reports --verbose
```

Options include `--help`, `--version`, `--project`, `--output`, `--verbose`, `--quiet`, and `--no-color`. Exit code `0` means the audit completed; `1` means report generation failed; `2` means invalid startup arguments or project path.

An optional `.project_doctor.yaml` can configure ignored paths and quality limits:

```yaml
ignore:
  - build/**
  - .dart_tool/**
max_file_size_mb: 5
max_method_lines: 100
max_widget_lines: 250
allow_print: false
allow_debug_print: false
max_concurrent_analyzers: 4
```

## Output

Reports are written as `project_report_YYYYMMDD_HHMMSS.txt`. They include a table of contents, execution metadata, analyzer timings, issues with severity and fixes, recommendations, and a final health score. The analyzer suite also audits architecture, imports, dependency cycles, code complexity, duplication, dead code, documentation coverage, API design, and Flutter widget size.

## Architecture

`Doctor` orchestrates immutable analyzer results. Each analyzer implements the `Analyzer` interface. `ProjectContext` owns project configuration, `FileScanner` caches filesystem metadata, and `ReportBuilder` streams deterministic text output. New analyzers for Android, Node.js, React, or Next.js can be added without modifying existing analyzers.

See [the sample report placeholder](docs/sample-report.txt).

## Development

```bash
dart format .
dart analyze
dart test
```

## Roadmap

- Richer package metadata and discontinued-package detection
- Pluggable ecosystem analyzer bundles
- Baseline comparison between reports
- Optional machine-readable output in a future major version

## License

MIT. See [LICENSE](LICENSE).
