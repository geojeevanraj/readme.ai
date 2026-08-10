import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_service.dart';
import 'reader_settings.dart';

/// Holds and mutates the reader's typography, persisting every change.
///
/// Settings are restored synchronously on first build, so the first page the
/// reader sees is already set the way they left it.
class ReaderSettingsController extends Notifier<ReaderSettings> {
  PreferencesService get _prefs => ref.read(preferencesProvider);

  @override
  ReaderSettings build() {
    final prefs = ref.read(preferencesProvider);
    return ReaderSettings(
      fontSize:
          prefs.readDouble(PreferenceKeys.readerFontSize) ??
          const ReaderSettings().fontSize,
      lineHeight:
          prefs.readDouble(PreferenceKeys.readerLineHeight) ??
          const ReaderSettings().lineHeight,
      typeface: ReaderTypeface.fromId(
        prefs.readString(PreferenceKeys.readerTypeface),
      ),
    );
  }

  /// Step the font size by [delta] positions along [ReaderSettings.fontSizeSteps].
  void stepFontSize(int delta) {
    const steps = ReaderSettings.fontSizeSteps;
    final next = (state.fontSizeIndex + delta).clamp(0, steps.length - 1);
    _setFontSize(steps[next]);
  }

  /// Step the line spacing by [delta] positions.
  void stepLineHeight(int delta) {
    const steps = ReaderSettings.lineHeightSteps;
    final next = (state.lineHeightIndex + delta).clamp(0, steps.length - 1);
    _setLineHeight(steps[next]);
  }

  /// Select the reading face.
  void selectTypeface(ReaderTypeface typeface) {
    if (state.typeface == typeface) return;
    state = state.copyWith(typeface: typeface);
    _prefs.writeString(PreferenceKeys.readerTypeface, typeface.id);
  }

  bool get canIncreaseFontSize =>
      state.fontSizeIndex < ReaderSettings.fontSizeSteps.length - 1;

  bool get canDecreaseFontSize => state.fontSizeIndex > 0;

  bool get canIncreaseLineHeight =>
      state.lineHeightIndex < ReaderSettings.lineHeightSteps.length - 1;

  bool get canDecreaseLineHeight => state.lineHeightIndex > 0;

  void _setFontSize(double value) {
    final clamped = value.clamp(
      ReaderSettings.minFontSize,
      ReaderSettings.maxFontSize,
    );
    if (clamped == state.fontSize) return;
    state = state.copyWith(fontSize: clamped);
    _prefs.writeDouble(PreferenceKeys.readerFontSize, clamped);
  }

  void _setLineHeight(double value) {
    final clamped = value.clamp(
      ReaderSettings.minLineHeight,
      ReaderSettings.maxLineHeight,
    );
    if (clamped == state.lineHeight) return;
    state = state.copyWith(lineHeight: clamped);
    _prefs.writeDouble(PreferenceKeys.readerLineHeight, clamped);
  }
}

/// Exposes the reader display settings.
final readerSettingsProvider =
    NotifierProvider<ReaderSettingsController, ReaderSettings>(
      ReaderSettingsController.new,
    );
