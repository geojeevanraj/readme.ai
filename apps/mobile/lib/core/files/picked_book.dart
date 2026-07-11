import 'dart:typed_data';

/// A file chosen by the user, ready to upload.
class PickedBook {
  const PickedBook({
    required this.filename,
    required this.bytes,
    this.mimeType,
  });

  /// Original file name including extension.
  final String filename;

  /// File contents.
  final Uint8List bytes;

  /// Best-effort MIME type, if the platform reported one.
  final String? mimeType;

  /// Size of the file in bytes.
  int get size => bytes.length;
}
