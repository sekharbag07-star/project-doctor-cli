import 'analyzer.dart';
import 'analyzer_metadata.dart';

/// Creates an analyzer when the registry needs to run it.
typedef AnalyzerFactory = Analyzer Function();

/// Associates an analyzer with its descriptive metadata.
class AnalyzerRegistration {
  /// Creates a lazy registration backed by [factory] and [metadata].
  const AnalyzerRegistration({required this.factory, required this.metadata});

  /// Factory used to create the analyzer.
  final AnalyzerFactory factory;

  /// Metadata describing the analyzer.
  final AnalyzerMetadata metadata;

  /// Creates the analyzer for this registration.
  Analyzer get analyzer => factory();
}

/// Ordered registry of analyzers available to one audit run.
class AnalyzerRegistry {
  final Map<String, AnalyzerRegistration> _registrations = {};

  /// Creates an empty registry.
  AnalyzerRegistry();

  /// Registers [analyzer], replacing an existing registration with the same id.
  void register(Object value,
      {AnalyzerMetadata? metadata, AnalyzerFactory? factory}) {
    final resolved = value is AnalyzerMetadata
        ? value
        : metadata ?? AnalyzerMetadata.legacy(value as Analyzer);
    final resolvedFactory = value is Analyzer ? () => value : factory;
    if (resolvedFactory == null) {
      throw ArgumentError('A factory is required for metadata registration.');
    }
    if (resolved.id.isEmpty) {
      throw ArgumentError.value(
          metadata, 'metadata', 'Analyzer id cannot be empty.');
    }
    _registrations[resolved.id] = AnalyzerRegistration(
      factory: resolvedFactory,
      metadata: resolved,
    );
  }

  /// Registers a lazy analyzer factory with explicit [metadata].
  void registerFactory(AnalyzerMetadata metadata, AnalyzerFactory factory) {
    register(metadata, factory: factory);
  }

  /// Registers all [analyzers] using legacy metadata where needed.
  void registerAll(Iterable<Analyzer> analyzers) {
    for (final analyzer in analyzers) {
      register(analyzer);
    }
  }

  /// Removes the analyzer identified by [id], returning whether it existed.
  bool unregister(String id) => _registrations.remove(id) != null;

  /// Returns the registration for [id], if present.
  AnalyzerRegistration? find(String id) => _registrations[id];

  /// Returns registrations in insertion order.
  Iterable<AnalyzerRegistration> get registrations =>
      List.unmodifiable(_registrations.values);

  /// Returns analyzers in registry order for execution.
  Iterable<Analyzer> get analyzers =>
      registrations.map((entry) => entry.analyzer);

  /// Returns whether the registry contains [id].
  bool contains(String id) => _registrations.containsKey(id);
}
