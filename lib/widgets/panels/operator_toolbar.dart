import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/output_window_provider.dart';
import '../../providers/playback_provider.dart';

class OperatorToolbar extends ConsumerWidget {
  const OperatorToolbar({
    required this.onPickWorkspace,
    required this.onOpenSettings,
    required this.onToggleOutput,
    required this.onImportFile,
    required this.onImportClipboard,
    required this.onOpenStyles,
    required this.onOpenEditor,
    super.key,
  });

  final VoidCallback onPickWorkspace;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleOutput;
  final VoidCallback onImportFile;
  final VoidCallback onImportClipboard;
  final VoidCallback onOpenStyles;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outputWindow = ref.watch(outputWindowProvider);
    final playback = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final outputOpen = outputWindow.isOpen;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: outputWindow.isOpen
                        ? Icons.cast_connected
                        : Icons.cast,
                    label: outputWindow.isReconnecting
                        ? '재연결…'
                        : outputWindow.isOpen
                            ? '송출 ON'
                            : '송출',
                    selected: outputWindow.isOpen,
                    onPressed:
                        outputWindow.isReconnecting ? null : onToggleOutput,
                  ),
                  const _ThinSeparator(),
                  _ToolbarButton(
                    icon: Icons.brightness_2,
                    label: 'black',
                    selected: playback.isBlack,
                    onPressed: !outputOpen
                        ? null
                        : () => playbackNotifier.toggleBlack(),
                  ),
                  _ToolbarButton(
                    icon: Icons.layers,
                    label: 'still',
                    selected: playback.isStill,
                    onPressed: !outputOpen
                        ? null
                        : () => playbackNotifier.toggleStill(),
                  ),
                  const _ThickSeparator(),
                  _ToolbarButton(
                    icon: Icons.upload_file,
                    label: 'Import file',
                    onPressed: onImportFile,
                  ),
                  _ToolbarButton(
                    icon: Icons.content_paste,
                    label: 'Import Clipboard',
                    onPressed: onImportClipboard,
                  ),
                  _ToolbarButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onPressed: playback.currentSub == null ? null : onOpenEditor,
                  ),
                  _ToolbarButton(
                    icon: Icons.palette_outlined,
                    label: 'Style',
                    onPressed: onOpenStyles,
                  ),
                  const _ThickSeparator(),
                  _ToolbarButton(
                    icon: Icons.folder_open,
                    label: 'workspace',
                    onPressed: onPickWorkspace,
                  ),
                  _ToolbarButton(
                    icon: Icons.settings,
                    label: 'setting',
                    onPressed: onOpenSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected ? colorScheme.primary : null,
        backgroundColor: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, kToolbarHeight - 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

class _ThinSeparator extends StatelessWidget {
  const _ThinSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '|',
        style: TextStyle(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ThickSeparator extends StatelessWidget {
  const _ThickSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: kToolbarHeight * 0.5,
        child: VerticalDivider(
          width: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
