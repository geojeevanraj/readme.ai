import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/files/file_picker_service.dart';
import '../../../core/files/picked_book.dart';
import '../domain/library_repository.dart';
import 'library_controller.dart';
import 'library_providers.dart';

/// A file on its way into the library.
@immutable
class UploadJob {
  const UploadJob({
    required this.filename,
    this.fraction = 0,
    this.failed = false,
  });

  final String filename;

  /// Bytes sent, 0–1. Reaches 1 while the server is still creating the book.
  final double fraction;

  /// True when the upload failed and the reader can retry or dismiss.
  final bool failed;

  bool get isComplete => fraction >= 1 && !failed;

  UploadJob copyWith({double? fraction, bool? failed}) => UploadJob(
    filename: filename,
    fraction: fraction ?? this.fraction,
    failed: failed ?? this.failed,
  );
}

/// Owns the in-flight upload so the library can show a real progress row
/// instead of swallowing the file until the request finishes.
///
/// The picked file is kept so a failed upload can be retried without asking the
/// reader to find it again — the most annoying part of a failed upload is having
/// to repeat the file picker.
class UploadController extends Notifier<UploadJob?> {
  PickedBook? _pending;

  LibraryRepository get _repository => ref.read(libraryRepositoryProvider);

  @override
  UploadJob? build() => null;

  /// Open the picker and upload the chosen file. Returns false if the reader
  /// cancelled the picker.
  Future<bool> pickAndUpload() async {
    final picked = await ref.read(filePickerProvider).pickBook();
    if (picked == null) return false;
    _pending = picked;
    await _send(picked);
    return true;
  }

  /// Retry the last file that failed to upload.
  Future<void> retry() async {
    final pending = _pending;
    if (pending == null) return;
    await _send(pending);
  }

  /// Dismiss a failed upload.
  void dismiss() {
    _pending = null;
    state = null;
  }

  Future<void> _send(PickedBook file) async {
    state = UploadJob(filename: file.filename);
    try {
      await _repository.uploadBook(
        file,
        onProgress: (fraction) {
          // Guard against late callbacks after the job was dismissed.
          if (state?.filename == file.filename) {
            state = state?.copyWith(fraction: fraction);
          }
        },
      );
      _pending = null;
      state = null;
      // The new book arrives in the list as PROCESSING; the library controller
      // takes over from here and polls until it is ready.
      await ref.read(libraryControllerProvider.notifier).refresh();
    } on Object {
      state =
          state?.copyWith(failed: true) ??
          UploadJob(filename: file.filename, failed: true);
    }
  }
}

/// Exposes the current upload, if any.
final uploadControllerProvider = NotifierProvider<UploadController, UploadJob?>(
  UploadController.new,
);
