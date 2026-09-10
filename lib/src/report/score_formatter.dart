/// Formats health scores for report output.
class ScoreFormatter {
  /// Creates a score formatter.
  const ScoreFormatter();

  /// Formats [score] as a compact progress bar and percentage.
  String format(int score, {int width = 10}) {
    final bounded = score.clamp(0, 100);
    final filled = (bounded * width / 100).round();
    return '${'█' * filled}${'░' * (width - filled)} $bounded%';
  }
}
