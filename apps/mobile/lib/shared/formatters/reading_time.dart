/// Estimates for how much reading is left.
///
/// A reader does not think in characters or scroll offsets; they think in
/// minutes. 1,000 characters per minute ≈ 200 words per minute at an average
/// English word length of five characters, which is a conservative adult
/// silent-reading pace.
abstract final class ReadingTime {
  static const int charactersPerMinute = 1000;

  /// Whole minutes of reading left in a book of [characterCount] characters
  /// when [fraction] (0–1) of it has been read.
  static int minutesRemaining(int characterCount, double fraction) {
    if (characterCount <= 0) return 0;
    final remaining = characterCount * (1 - fraction.clamp(0.0, 1.0));
    return (remaining / charactersPerMinute).round();
  }
}
