import 'dart:typed_data';

import 'package:readme_ai/core/files/file_picker_service.dart';
import 'package:readme_ai/core/files/picked_book.dart';

/// A [FilePickerService] that returns a preset result (or `null` for cancel).
class FakeFilePicker implements FilePickerService {
  FakeFilePicker({this.result});

  PickedBook? result;

  /// A convenience picked file with dummy bytes.
  static PickedBook sampleBook({String filename = 'sample.pdf'}) => PickedBook(
    filename: filename,
    bytes: Uint8List.fromList(const [37, 80, 68, 70]),
    mimeType: 'application/pdf',
  );

  @override
  Future<PickedBook?> pickBook() async => result;
}
