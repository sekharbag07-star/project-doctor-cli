/// Exception describing a controlled analyzer failure.
class AnalyzerException implements Exception {
  /// Creates an exception with a user-facing diagnostic message.
  const AnalyzerException(this.message);

  /// Diagnostic text explaining the failure.
  final String message;

  @override
  String toString() => message;
}
