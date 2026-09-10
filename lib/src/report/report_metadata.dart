/// Immutable metadata describing one generated report.
class ReportMetadata {
  /// Creates report metadata.
  const ReportMetadata({
    required this.projectName,
    required this.generatedAt,
    required this.doctorVersion,
    required this.projectLocation,
    required this.executionDuration,
    required this.operatingSystem,
  });

  /// Audited project name.
  final String projectName;

  /// Time at which report generation started.
  final DateTime generatedAt;

  /// Project Doctor version.
  final String doctorVersion;

  /// Absolute or configured project location.
  final String projectLocation;

  /// Total execution duration.
  final Duration executionDuration;

  /// Host operating system name.
  final String operatingSystem;
}
