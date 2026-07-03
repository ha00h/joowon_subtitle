import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_release_info.dart';
import '../../providers/update_provider.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context,
  WidgetRef ref, {
  required AppReleaseInfo release,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _UpdateAvailableDialog(release: release),
  );
}

class _UpdateAvailableDialog extends ConsumerWidget {
  const _UpdateAvailableDialog({required this.release});

  final AppReleaseInfo release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.read(updateProvider.notifier);
    final current = ref.read(updateProvider).currentVersion;

    return AlertDialog(
      title: Text('새 버전 v${release.version}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current != null)
              Text(
                '현재 버전: v$current',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            if (release.releaseNotes != null) ...[
              Text(
                release.releaseNotes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else
              const Text('새 버전이 GitHub Releases에 올라와 있습니다.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            update.dismissForNow();
            Navigator.pop(context);
          },
          child: const Text('나중에'),
        ),
        TextButton(
          onPressed: () async {
            await update.skipVersion(release.version);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('이 버전 건너뛰기'),
        ),
        FilledButton(
          onPressed: () async {
            await update.openDownload(release);
            update.dismissForNow();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('다운로드'),
        ),
      ],
    );
  }
}
