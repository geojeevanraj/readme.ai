import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'picked_book.dart';

/// Best-effort MIME type for the document formats accepted by the picker.
String bookMimeType(String filename) {
  final normalized = filename.toLowerCase();
  if (normalized.endsWith('.pdf')) return 'application/pdf';
  if (normalized.endsWith('.txt')) return 'text/plain';
  return 'application/octet-stream';
}

/// Abstraction over the platform file picker so the upload flow can be tested
/// without invoking native plugins.
abstract interface class FilePickerService {
  /// Prompt the user to pick a book file. Returns `null` if cancelled.
  Future<PickedBook?> pickBook();
}

/// [FilePickerService] backed by the `file_picker` plugin.
class FilePickerServiceImpl implements FilePickerService {
  const FilePickerServiceImpl();

  @override
  Future<PickedBook?> pickBook() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return null;
    }
    return PickedBook(
      filename: file.name,
      bytes: bytes,
      mimeType: bookMimeType(file.name),
    );
  }
}

/// Provides the file picker. Overridden in tests with a fake.
final filePickerProvider = Provider<FilePickerService>(
  (ref) => const FilePickerServiceImpl(),
);
