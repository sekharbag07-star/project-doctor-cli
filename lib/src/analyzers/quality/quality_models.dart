import '../issue.dart';

/// Classification for a code-quality issue.
enum QualityCategory {
  /// Complexity and control-flow findings.
  complexity,

  /// Maintainability findings.
  maintainability,

  /// Duplication findings.
  duplication,

  /// Dead-code findings.
  deadCode,

  /// Style findings.
  style,

  /// Public API findings.
  apiDesign,

  /// Documentation findings.
  documentation,

  /// Flutter-specific findings.
  flutter,

  /// Naming findings.
  naming,

  /// Architecture and design findings.
  architecture,
}

/// Specific quality issue kind.
enum IssueType {
  /// Long method issue.
  longMethod,

  /// God class issue.
  godClass,

  /// Duplicate code issue.
  duplicateCode,

  /// Dead code issue.
  deadCode,

  /// Unused import issue.
  unusedImport,

  /// Large file issue.
  largeFile,

  /// Deep nesting issue.
  deepNesting,

  /// Magic number issue.
  magicNumber,

  /// TODO marker issue.
  todo,

  /// Deprecated API issue.
  deprecatedApi,

  /// Naming issue.
  naming,

  /// Missing documentation issue.
  missingDocumentation,

  /// Widget complexity issue.
  widgetComplexity,

  /// Mutable API issue.
  mutableApi,

  /// SOLID design issue.
  solidViolation,
}

/// Immutable source location associated with a quality issue.
class CodeLocation {
  /// Creates a source location.
  const CodeLocation({required this.file, this.line = 0, this.column = 0});

  /// Normalized project-relative file path.
  final String file;

  /// One-based source line.
  final int line;

  /// One-based source column.
  final int column;
}

/// Immutable recommendation for resolving a quality issue.
class Recommendation {
  /// Creates a recommendation.
  const Recommendation({
    required this.problem,
    required this.reason,
    required this.impact,
    required this.suggestedFix,
    required this.example,
    required this.priority,
    required this.estimatedMinutes,
    this.references = const [],
  });

  /// Problem statement.
  final String problem;

  /// Why the problem matters.
  final String reason;

  /// Expected impact if unresolved.
  final String impact;

  /// Suggested remediation.
  final String suggestedFix;

  /// Example remediation.
  final String example;

  /// Urgency label.
  final String priority;

  /// Estimated remediation time.
  final int estimatedMinutes;

  /// Supporting references.
  final List<String> references;
}

/// Optional automated fix suggestion.
class AutoFixSuggestion {
  /// Creates an auto-fix suggestion.
  const AutoFixSuggestion(
      {required this.description, required this.replacement});

  /// Human-readable fix description.
  final String description;

  /// Replacement text or command.
  final String replacement;
}

/// Immutable quality issue with structured location and remediation data.
class CodeIssue {
  /// Creates a quality issue.
  CodeIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.issueType,
    required List<CodeLocation> locations,
    required this.recommendation,
    this.autoFix,
  }) : locations = List.unmodifiable(locations);

  /// Stable issue identifier.
  final String id;

  /// Short issue title.
  final String title;

  /// Detailed issue description.
  final String description;

  /// Severity used by the legacy report and score engine.
  final Severity severity;

  /// Quality category.
  final QualityCategory category;

  /// Specific issue type.
  final IssueType issueType;

  /// Source locations.
  final List<CodeLocation> locations;

  /// Structured remediation recommendation.
  final Recommendation recommendation;

  /// Optional automated fix.
  final AutoFixSuggestion? autoFix;

  /// Converts the issue to the existing report issue model.
  Issue toIssue() => Issue(
        severity: severity,
        problem: title,
        reason: description,
        files: locations.map((location) => location.file).toList(),
        recommendedFix: recommendation.suggestedFix,
        priority: recommendation.priority,
      );
}

/// Aggregate code metric snapshot.
class CodeMetric {
  /// Creates a metric snapshot.
  const CodeMetric({
    required this.linesOfCode,
    required this.sourceLines,
    required this.commentRatio,
    required this.documentationPercent,
    required this.averageFunctionSize,
    required this.averageClassSize,
    required this.averageNesting,
    required this.averageParameters,
    required this.dependencyCount,
    required this.fileFanIn,
    required this.fileFanOut,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
    required this.maintainabilityIndex,
  });

  /// Physical lines.
  final int linesOfCode;

  /// Non-empty, non-comment lines.
  final int sourceLines;

  /// Comment-to-source ratio.
  final double commentRatio;

  /// Percentage of public declarations with documentation.
  final double documentationPercent;

  /// Average function size in lines.
  final double averageFunctionSize;

  /// Average class size in lines.
  final double averageClassSize;

  /// Average nesting depth.
  final double averageNesting;

  /// Average function parameter count.
  final double averageParameters;

  /// Number of imports.
  final int dependencyCount;

  /// Number of files importing this file.
  final int fileFanIn;

  /// Number of files this file imports.
  final int fileFanOut;

  /// Estimated cyclomatic complexity.
  final double cyclomaticComplexity;

  /// Estimated cognitive complexity.
  final double cognitiveComplexity;

  /// Maintainability index from 0 to 100.
  final double maintainabilityIndex;
}

/// Aggregate quality score dimensions.
class QualityScore {
  /// Creates quality scores.
  const QualityScore({
    required this.maintainability,
    required this.complexity,
    required this.documentation,
    required this.codeQuality,
    required this.overall,
  });

  /// Maintainability score.
  final int maintainability;

  /// Complexity score.
  final int complexity;

  /// Documentation score.
  final int documentation;

  /// Code quality score.
  final int codeQuality;

  /// Overall quality score.
  final int overall;
}

/// Estimated technical debt for a quality issue set.
class TechnicalDebt {
  /// Creates a technical debt estimate.
  const TechnicalDebt(
      {required this.minutes,
      required this.priority,
      required this.risk,
      required this.impact});

  /// Estimated remediation minutes.
  final int minutes;

  /// Debt priority.
  final String priority;

  /// Risk if deferred.
  final String risk;

  /// Expected impact of remediation.
  final String impact;

  /// Estimated debt hours.
  double get hours => minutes / 60;

  /// Estimated debt days using an eight-hour workday.
  double get days => hours / 8;
}
