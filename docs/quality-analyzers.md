# Quality Analyzers

Phase 6 adds independent code-quality analyzers under `lib/src/analyzers/quality/`.

The suite reuses the cached `SourceInventory` from `ProjectContext`, so analyzers do not perform duplicate Dart file traversal or parsing. Each analyzer returns the existing `AnalyzerResult` contract and maps immutable `CodeIssue` values into legacy report issues.

## Coverage

- Complexity, long methods, and god classes
- Token-window duplicate code detection
- Dead private declarations
- TODO/FIXME, deprecated APIs, and magic numbers
- Flutter widget size checks
- SOLID, naming, API design, and documentation coverage
- Maintainability metrics and aggregate quality score

The quality models are immutable and include `CodeLocation`, `Recommendation`, `AutoFixSuggestion`, `TechnicalDebt`, `CodeMetric`, and `QualityScore`.
