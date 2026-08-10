import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantics.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/appearance_controller.dart';
import '../../../../core/theme/reading_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/reader_settings.dart';
import '../../application/reader_settings_controller.dart';

/// Bottom sheet for adjusting how the page is set.
///
/// Every control has a live sample directly above it, so the reader judges a
/// typography change by looking at type rather than at a number. The three
/// appearance options double as the app's light/dark control — there is no
/// second "dark mode" switch to contradict them.
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    final settings = ref.watch(readerSettingsProvider);
    final controller = ref.read(readerSettingsProvider.notifier);
    final appearance = ref.watch(appearanceProvider);
    final palette = ReadingPalette.of(appearance);

    return SafeArea(
      child: ConstrainedBox(
        // Tall enough for every control to be reachable, short enough that the
        // page underneath stays partly visible.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.sm,
            Space.lg,
            Space.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live sample. This is the whole point of the sheet.
              AnimatedContainer(
                duration: Motion.of(context, Motion.fast),
                curve: Motion.standard,
                padding: const EdgeInsets.all(Space.base),
                decoration: BoxDecoration(
                  color: palette.canvas,
                  borderRadius: Radii.all(Radii.md),
                  border: Border.all(color: palette.hairline),
                ),
                child: Text(
                  l10n.readerPreviewSentence,
                  style: AppTypography.reading(
                    fontSize: settings.fontSize,
                    lineHeight: settings.lineHeight,
                    color: palette.ink,
                    serif: settings.typeface.isSerif,
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),

              _SectionLabel(l10n.readerAppearance),
              const SizedBox(height: Space.sm),
              _AppearanceRow(
                selected: appearance,
                onSelected: (choice) =>
                    ref.read(appearanceProvider.notifier).select(choice),
              ),
              const SizedBox(height: Space.lg),

              _SectionLabel(l10n.readerTypeface),
              const SizedBox(height: Space.sm),
              SegmentedButton<ReaderTypeface>(
                segments: [
                  ButtonSegment(
                    value: ReaderTypeface.serif,
                    label: Text(
                      l10n.readerTypefaceSerif,
                      style: const TextStyle(
                        fontFamily: AppTypography.serifFamily,
                        fontFamilyFallback: AppTypography.serifFallback,
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: ReaderTypeface.sans,
                    label: Text(l10n.readerTypefaceSans),
                  ),
                ],
                selected: {settings.typeface},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    controller.selectTypeface(selection.first),
              ),
              const SizedBox(height: Space.lg),

              _StepperRow(
                label: l10n.readerTextSize,
                value: '${settings.fontSize.round()}',
                icon: Icons.format_size_rounded,
                onDecrease: controller.canDecreaseFontSize
                    ? () => controller.stepFontSize(-1)
                    : null,
                onIncrease: controller.canIncreaseFontSize
                    ? () => controller.stepFontSize(1)
                    : null,
              ),
              Divider(color: semantics.hairline, height: Space.xl),
              _StepperRow(
                label: l10n.readerLineSpacing,
                value: settings.lineHeight.toStringAsFixed(2),
                icon: Icons.format_line_spacing_rounded,
                onDecrease: controller.canDecreaseLineHeight
                    ? () => controller.stepLineHeight(-1)
                    : null,
                onIncrease: controller.canIncreaseLineHeight
                    ? () => controller.stepLineHeight(1)
                    : null,
              ),
              const SizedBox(height: Space.sm),
              Text(
                l10n.readerSettingsFootnote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantics.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paper / Sepia / Night, shown as swatches rather than words alone: the
/// reader is choosing a surface, so the control should look like the surfaces.
class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow({required this.selected, required this.onSelected});

  final ReadingTheme selected;
  final ValueChanged<ReadingTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final labels = {
      ReadingTheme.paper: l10n.readerAppearancePaper,
      ReadingTheme.sepia: l10n.readerAppearanceSepia,
      ReadingTheme.night: l10n.readerAppearanceNight,
    };

    return Row(
      children: [
        for (final theme in ReadingTheme.values) ...[
          Expanded(
            child: _AppearanceSwatch(
              label: labels[theme]!,
              palette: ReadingPalette.of(theme),
              isSelected: theme == selected,
              onTap: () => onSelected(theme),
            ),
          ),
          if (theme != ReadingTheme.values.last)
            const SizedBox(width: Space.sm),
        ],
      ],
    );
  }
}

class _AppearanceSwatch extends StatelessWidget {
  const _AppearanceSwatch({
    required this.label,
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final ReadingPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.all(Radii.md),
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          height: 76,
          decoration: BoxDecoration(
            color: palette.canvas,
            borderRadius: Radii.all(Radii.md),
            border: Border.all(
              color: isSelected ? semantics.accent : semantics.hairline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  fontFamily: AppTypography.serifFamily,
                  fontFamilyFallback: AppTypography.serifFallback,
                  fontSize: 19,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: context.semantics.inkMuted),
    );
  }
}

/// A labelled value with −/+ controls. Both buttons keep a 48dp target and
/// disable at the ends of the range instead of silently doing nothing.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Row(
      children: [
        Icon(icon, size: 20, color: semantics.inkFaint),
        const SizedBox(width: Space.md),
        Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
        IconButton.filledTonal(
          tooltip: l10n.decreaseLabel(label),
          onPressed: onDecrease,
          icon: const Icon(Icons.remove_rounded, size: 20),
        ),
        SizedBox(
          width: 48,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: semantics.inkMuted,
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: l10n.increaseLabel(label),
          onPressed: onIncrease,
          icon: const Icon(Icons.add_rounded, size: 20),
        ),
      ],
    );
  }
}
