import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_controller.dart';
import '../../application/reader_settings.dart';
import '../../application/reader_settings_controller.dart';

/// Bottom sheet for adjusting reader typography and theme.
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final controller = ref.read(readerSettingsProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _StepperRow(
              icon: Icons.format_size,
              label: 'Font size',
              value: settings.fontSize.round().toString(),
              onDecrease: settings.fontSize > ReaderSettings.minFontSize
                  ? controller.decreaseFontSize
                  : null,
              onIncrease: settings.fontSize < ReaderSettings.maxFontSize
                  ? controller.increaseFontSize
                  : null,
            ),
            const SizedBox(height: 8),
            _StepperRow(
              icon: Icons.format_line_spacing,
              label: 'Line spacing',
              value: settings.lineHeight.toStringAsFixed(1),
              onDecrease: settings.lineHeight > ReaderSettings.minLineHeight
                  ? controller.decreaseLineHeight
                  : null,
              onIncrease: settings.lineHeight < ReaderSettings.maxLineHeight
                  ? controller.increaseLineHeight
                  : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              value: isDark,
              onChanged: (enabled) => ref
                  .read(themeModeProvider.notifier)
                  .setMode(enabled ? ThemeMode.dark : ThemeMode.light),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        IconButton.filledTonal(
          tooltip: 'Decrease $label',
          onPressed: onDecrease,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(width: 44, child: Text(value, textAlign: TextAlign.center)),
        IconButton.filledTonal(
          tooltip: 'Increase $label',
          onPressed: onIncrease,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
