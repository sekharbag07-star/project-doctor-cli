import 'analyzer.dart';

/// Broad responsibility area used to classify an analyzer.
enum AnalyzerCategory {
  /// Host tools and SDK availability.
  environment,

  /// Project-level metadata and inventory.
  project,

  /// Flutter-specific diagnostics.
  flutter,

  /// Dart-specific diagnostics.
  dart,

  /// Git and repository history checks.
  git,

  /// Package and dependency checks.
  dependencies,

  /// Layering and architectural rules.
  architecture,

  /// Repository hygiene checks.
  repository,

  /// Feature organization checks.
  feature,

  /// Source and project measurements.
  metrics,

  /// Security and secret detection.
  security,

  /// Runtime and source performance checks.
  performance,

  /// Maintainability and code quality checks.
  quality,

  /// Asset checks.
  assets,

  /// Dead-code checks.
  deadCode,

  /// Duplicate-file or duplicate-code checks.
  duplicateDetection,

  /// Generated-file checks.
  generatedFiles,

  /// Project structure checks.
  projectStructure,

  /// Recommendation-only sections.
  recommendations,

  /// A plugin-specific category not yet standardized.
  other,
}

/// Project ecosystems that can be audited by a plugin.
enum ProjectType {
  /// A Dart package or command-line project.
  dart,

  /// A Flutter application or package.
  flutter,

  /// An Android project.
  android,

  /// A Kotlin project.
  kotlin,

  /// A React project.
  react,

  /// A Next.js project.
  nextJs,

  /// A Node.js project.
  node,

  /// A project whose ecosystem is not detected.
  unknown,
}

/// Immutable descriptive metadata for an analyzer.
class AnalyzerMetadata {
  /// Creates metadata used by registries and plugin consumers.
  AnalyzerMetadata({
    required this.id,
    required this.displayName,
    required this.description,
    required this.category,
    required List<ProjectType> supportedProjectTypes,
    this.estimatedDuration = Duration.zero,
    this.enabledByDefault = true,
  }) : supportedProjectTypes = List.unmodifiable(supportedProjectTypes);

  /// Stable machine-readable identifier.
  final String id;

  /// Human-readable name used in user-facing surfaces.
  final String displayName;

  /// Responsibility and scope of the analyzer.
  final String description;

  /// Primary category of the analyzer.
  final AnalyzerCategory category;

  /// Ecosystems supported by the analyzer.
  final List<ProjectType> supportedProjectTypes;

  /// Typical execution time, when known.
  final Duration estimatedDuration;

  /// Whether the analyzer runs when no explicit selection is configured.
  final bool enabledByDefault;

  /// Builds conservative metadata for an existing legacy [analyzer].
  factory AnalyzerMetadata.legacy(Analyzer analyzer) {
    final displayName = analyzer.name;
    return AnalyzerMetadata(
      id: _slugify(displayName),
      displayName: displayName,
      description: 'Legacy analyzer: $displayName.',
      category: AnalyzerCategory.other,
      supportedProjectTypes: const [ProjectType.dart, ProjectType.flutter],
    );
  }

  static String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-'), '');
}
