import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/workspace_picker.dart';
import '../../providers/output_window_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/dialogs/update_available_dialog.dart';
import '../../providers/style_provider.dart';
import '../../providers/workspace_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final styleState = ref.watch(styleProvider);
    final monitorsAsync = ref.watch(monitorsProvider);
    final updateState = ref.watch(updateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('작업 폴더'),
            subtitle: Text(settings.workspacePath ?? '미설정'),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              try {
                await _pickWorkspace(ref);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('폴더 선택 실패: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('활성 스타일'),
            subtitle: Text(styleState.style.name),
            trailing: const Icon(Icons.palette),
          ),
          const Divider(),
          const ListTile(title: Text('출력 모니터')),
          monitorsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => _MonitorWarning(
              message: '모니터 목록을 불러오지 못했습니다: $e',
            ),
            data: (result) {
              if (result.isFallback) {
                return _MonitorWarning(
                  message: result.error ??
                      '모니터 API를 사용할 수 없어 더미 목록을 표시합니다.',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          monitorsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (result) {
              final monitors = result.monitors;
              if (monitors.isEmpty) {
                return const ListTile(title: Text('모니터 없음'));
              }
              return Column(
                children: monitors.map((m) {
                  return RadioListTile<String>(
                    title: Text(m.label),
                    subtitle: m.isDummy
                        ? const Text('테스트용 더미 모니터')
                        : Text('ID: ${m.id}'),
                    value: m.id,
                    groupValue: settings.outputMonitorId ?? monitors.first.id,
                    onChanged: (id) async {
                      if (id == null) return;
                      await ref
                          .read(settingsProvider.notifier)
                          .setOutputMonitorId(id);
                      if (ref.read(outputWindowProvider).isOpen) {
                        await ref
                            .read(outputWindowProvider.notifier)
                            .reopenOnMonitorChange();
                      }
                      ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
                    },
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
          const ListTile(title: Text('송출 배경')),
          RadioListTile<OutputBackground>(
            title: const Text('검정 (Luma Key)'),
            value: OutputBackground.black,
            groupValue: settings.outputBackground,
            onChanged: (v) async {
              if (v == null) return;
              await ref.read(settingsProvider.notifier).setOutputBackground(v);
              ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
            },
          ),
          RadioListTile<OutputBackground>(
            title: const Text('투명 (Alpha)'),
            subtitle: const Text('Windows/macOS 지원 여부는 환경에 따라 다릅니다'),
            value: OutputBackground.transparent,
            groupValue: settings.outputBackground,
            onChanged: (v) async {
              if (v == null) return;
              await ref.read(settingsProvider.notifier).setOutputBackground(v);
              ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('앱 버전'),
            subtitle: Text(_updateStatusText(updateState)),
            trailing: updateState.status == UpdateStatus.checking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton.tonal(
                    onPressed: () => _checkForUpdate(context, ref),
                    child: const Text('업데이트 확인'),
                  ),
          ),
        ],
      ),
    );
  }

  String _updateStatusText(UpdateState state) {
    final current = state.currentVersion ?? '…';
    return switch (state.status) {
      UpdateStatus.available =>
        '현재 v$current · v${state.release!.version} 사용 가능',
      UpdateStatus.error => '현재 v$current · ${state.errorMessage}',
      UpdateStatus.checking => '현재 v$current · 확인 중…',
      _ => '현재 v$current',
    };
  }

  Future<void> _checkForUpdate(BuildContext context, WidgetRef ref) async {
    await ref.read(updateProvider.notifier).checkManual();
    if (!context.mounted) return;

    final updateState = ref.read(updateProvider);
    if (updateState.status == UpdateStatus.available &&
        updateState.release != null) {
      await showUpdateAvailableDialog(
        context,
        ref,
        release: updateState.release!,
      );
      return;
    }

    final message = switch (updateState.status) {
      UpdateStatus.upToDate => '최신 버전입니다.',
      UpdateStatus.error => updateState.errorMessage ?? '업데이트 확인에 실패했습니다.',
      _ => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _pickWorkspace(WidgetRef ref) async {
    final picked = await pickWorkspaceDirectory(
      initialDirectory: ref.read(settingsProvider).workspacePath,
    );
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setWorkspacePath(
          picked.path,
          bookmark: picked.bookmark,
        );
    ref.read(workspaceProvider.notifier).setRootPath(picked.path);
  }
}

class _MonitorWarning extends StatelessWidget {
  const _MonitorWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MaterialBanner(
        content: Text(message),
        leading: const Icon(Icons.warning_amber, color: Colors.amber),
        actions: const [SizedBox.shrink()],
      ),
    );
  }
}
