/// How the backend classified a selection. The user never chooses this.
enum SelectionType {
  word,
  sentence,
  paragraph;

  /// Parse the backend's selection type, defaulting to [sentence].
  static SelectionType fromApi(String value) {
    return switch (value.toLowerCase()) {
      'word' => SelectionType.word,
      'sentence' => SelectionType.sentence,
      'paragraph' => SelectionType.paragraph,
      _ => SelectionType.sentence,
    };
  }
}
