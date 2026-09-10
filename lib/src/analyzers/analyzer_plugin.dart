import 'analyzer.dart';
import 'analyzer_metadata.dart';
import 'analyzer_registry.dart';

/// Supplies a cohesive group of analyzers for one ecosystem or capability.
abstract interface class AnalyzerPlugin {
  /// Stable plugin identifier.
  String get id;

  /// Creates the analyzers contributed by this plugin.
  Iterable<Analyzer> createAnalyzers();

  /// Provides metadata for analyzers returned by [createAnalyzers].
  AnalyzerMetadata metadataFor(Analyzer analyzer);
}

/// Loads analyzer plugins into an [AnalyzerRegistry].
class PluginManager {
  /// Creates a plugin manager backed by [registry].
  PluginManager(this.registry);

  /// Registry populated by this manager.
  final AnalyzerRegistry registry;

  /// Registers every analyzer supplied by [plugin].
  void register(AnalyzerPlugin plugin) {
    for (final analyzer in plugin.createAnalyzers()) {
      registry.register(analyzer, metadata: plugin.metadataFor(analyzer));
    }
  }

  /// Registers legacy analyzers that do not yet implement a plugin.
  void registerLegacy(Iterable<Analyzer> analyzers) {
    registry.registerAll(analyzers);
  }
}
