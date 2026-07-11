/// Lifecycle status of a book, mirroring the backend `BookStatus`.
enum BookStatus {
  uploading,
  uploaded,
  processing,
  ready,
  failed;

  /// Parse the backend's uppercase status string, defaulting to [uploaded]
  /// for any unrecognised value so the UI degrades gracefully.
  static BookStatus fromApi(String value) {
    return switch (value.toUpperCase()) {
      'UPLOADING' => BookStatus.uploading,
      'UPLOADED' => BookStatus.uploaded,
      'PROCESSING' => BookStatus.processing,
      'READY' => BookStatus.ready,
      'FAILED' => BookStatus.failed,
      _ => BookStatus.uploaded,
    };
  }

  /// A human-readable label for display.
  String get label => switch (this) {
    BookStatus.uploading => 'Uploading',
    BookStatus.uploaded => 'Uploaded',
    BookStatus.processing => 'Processing',
    BookStatus.ready => 'Ready',
    BookStatus.failed => 'Failed',
  };
}
