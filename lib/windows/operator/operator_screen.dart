import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/import_flow.dart';
import '../../services/app_shutdown.dart';
import '../../services/workspace_picker.dart';
import '../../providers/output_window_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/style_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/dialogs/update_available_dialog.dart';
import '../../widgets/common/panel_resize_handle.dart';
import '../../widgets/panels/operator_keyboard_shortcuts.dart';
import '../../widgets/panels/operator_search_panel.dart';
import '../../widgets/panels/operator_status_bar.dart';
import '../../widgets/panels/operator_toolbar.dart';
import '../../widgets/panels/slide_operator_panel.dart';
import 'settings_screen.dart';
import 'style_screen.dart';
import '../../widgets/editor/unified_editor_screen.dart';

class OperatorScreen extends ConsumerStatefulWidget {
  const OperatorScreen({super.key});

  @override
  ConsumerState<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends ConsumerState<OperatorScreen> {
  final _playbackFocusNode = FocusNode(debugLabel: 'playback');
  double? _dragPanelWidth;

  @override
  void dispose() {
    _playbackFocusNode.dispose();
    super.dispose();
  }

  void _focusPlaybackArea() {
    _playbackFocusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSettings());
  }

  Future<void> _restoreSettings() async {
    await ref.read(settingsProvider.notifier).restoreSecurityScopedAccess();
    ref.read(workspaceProvider.notifier).reloadFromSettings();

    await ref.read(styleProvider.notifier).initialize();

    final settings = ref.read(settingsProvider);
    final monitors = await ref.read(monitorsProvider.future);
    if (settings.outputMonitorId == null && monitors.monitors.isNotEmpty) {
      await ref
          .read(settingsProvider.notifier)
          .setOutputMonitorId(monitors.monitors.first.id);
    }

    if (monitors.isFallback && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('모니터 경고'),
            content: Text(
              monitors.error ??
                  '모니터 API를 사용할 수 없습니다. 더미 모니터 목록으로 UI를 표시합니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });
    }

    _scheduleAutomaticUpdateCheck();
  }

  void _scheduleAutomaticUpdateCheck() {
    Future<void>.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;
      await ref.read(updateProvider.notifier).checkAutomatic();
    });
  }

  Future<void> _toggleOutputWindow(WidgetRef ref) async {
    final notifier = ref.read(outputWindowProvider.notifier);
    if (ref.read(outputWindowProvider).isOpen) {
      await notifier.closeOutputWindow();
    } else {
      await notifier.openOutputWindow();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateProvider, (previous, next) {
      if (!next.pendingDialog || next.release == null || !mounted) return;
      ref.read(updateProvider.notifier).clearPendingDialog();
      showUpdateAvailableDialog(
        context,
        ref,
        release: next.release!,
      );
    });

    ref.listen(activeStyleFileProvider, (_, __) {
      ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
    });

    final settings = ref.watch(settingsProvider);
    final panelWidth = _dragPanelWidth ?? settings.operatorPanelWidth;

    return Shortcuts(
      shortcuts: operatorKeyboardShortcuts,
      child: Actions(
        actions: buildOperatorKeyboardActions(ref),
        child: Focus(
          focusNode: _playbackFocusNode,
          autofocus: true,
          child: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: panelWidth,
                  child: const OperatorSearchPanel(),
                ),
                PanelResizeHandle(
                  axis: Axis.horizontal,
                  onDelta: (dx) {
                    final base = _dragPanelWidth ?? settings.operatorPanelWidth;
                    final next = (base + dx).clamp(
                      AppSettings.minOperatorPanelWidth,
                      AppSettings.maxOperatorPanelWidth,
                    );
                    setState(() => _dragPanelWidth = next);
                  },
                  onDragEnd: () {
                    final width = _dragPanelWidth;
                    if (width == null) return;
                    ref
                        .read(settingsProvider.notifier)
                        .setOperatorPanelWidth(width);
                    setState(() => _dragPanelWidth = null);
                  },
                ),
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _focusPlaybackArea(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OperatorToolbar(
                          onToggleOutput: () => _toggleOutputWindow(ref),
                          onPickWorkspace: () => _pickWorkspaceFolder(ref),
                          onOpenSettings: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          onExit: () => unawaited(shutdownApplication(ref)),
                          onImportFile: () => ref
                              .read(importFlowProvider)
                              .importFromFile(context, ref),
                          onImportClipboard: () => ref
                              .read(importFlowProvider)
                              .importFromClipboard(context, ref),
                          onOpenStyles: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StyleScreen(),
                            ),
                          ),
                          onOpenEditor: () {
                            ref
                                .read(playbackProvider.notifier)
                                .prepareForSlideEdit();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UnifiedEditorScreen(
                                  mode: UnifiedEditorMode.slide,
                                ),
                              ),
                            );
                          },
                        ),
                        const Expanded(child: SlideOperatorPanel()),
                        const OperatorStatusBar(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _folderLabel(String? path) {
    if (path == null) return '작업 폴더';
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : '작업 폴더';
  }

  Future<void> _pickWorkspaceFolder(WidgetRef ref) async {
    try {
      final picked = await pickWorkspaceDirectory(
        initialDirectory: ref.read(settingsProvider).workspacePath,
      );
      if (picked == null) return;
      ref.read(workspaceProvider.notifier).setRootPath(picked.path);
      await ref.read(settingsProvider.notifier).setWorkspacePath(
            picked.path,
            bookmark: picked.bookmark,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('작업 폴더: ${_folderLabel(picked.path)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('폴더 선택 실패: $e')),
        );
      }
    }
  }
}
