/// How a book's content should be rendered, mirroring the backend.
enum ContentFormat {
  /// Reflowable plain text.
  text,

  /// A format the reader cannot render yet (e.g. PDF/EPUB).
  unsupported;

  /// Parse the backend's format string, defaulting to [unsupported].
  static ContentFormat fromApi(String value) {
    return switch (value.toLowerCase()) {
      'text' => ContentFormat.text,
      _ => ContentFormat.unsupported,
    };
  }
}
