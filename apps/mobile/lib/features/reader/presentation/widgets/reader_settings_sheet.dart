import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_controller.dart';
import '../../application/reader_settings.dart';
import '../../application/reader_settings_controller.dart';

/// Bottom sheet for adjusting reader typography and appearance.
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reading style', style: theme.textTheme.titleLarge),
                    Text(
                      'Make the page feel right for you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ControlCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    secondary: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_outlined,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Dark mode'),
                    subtitle: Text(isDark ? 'Easy on the eyes' : 'Warm paper'),
                    value: isDark,
                    onChanged: (enabled) => ref
                        .read(themeModeProvider.notifier)
                        .setMode(enabled ? ThemeMode.dark : ThemeMode.light),
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  _StepperRow(
                    icon: Icons.format_size_rounded,
                    label: 'Font size',
                    value: settings.fontSize.round().toString(),
                    onDecrease: settings.fontSize > ReaderSettings.minFontSize
                        ? controller.decreaseFontSize
                        : null,
                    onIncrease: settings.fontSize < ReaderSettings.maxFontSize
                        ? controller.increaseFontSize
                        : null,
                  ),
                  Divider(color: theme.colorScheme.outlineVariant),
                  _StepperRow(
                    icon: Icons.format_line_spacing_rounded,
                    label: 'Line spacing',
                    value: settings.lineHeight.toStringAsFixed(1),
                    onDecrease:
                        settings.lineHeight > ReaderSettings.minLineHeight
                        ? controller.decreaseLineHeight
                        : null,
                    onIncrease:
                        settings.lineHeight < ReaderSettings.maxLineHeight
                        ? controller.increaseLineHeight
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: child,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
          IconButton.filledTonal(
            tooltip: 'Decrease $label',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 42,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge,
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Increase $label',
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
