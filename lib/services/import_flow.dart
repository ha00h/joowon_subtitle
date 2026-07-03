import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../providers/playback_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/style_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/dialogs/import_preview_dialog.dart';
import 'sub_io.dart';

class ImportFlow {
  ImportFlow({
    SubIo? subIo,
  }) : _subIo = subIo ?? SubIo();

  final SubIo _subIo;

  Future<void> importFromFile(BuildContext context, WidgetRef ref) async {
    final workspace = ref.read(settingsProvider).workspacePath;
    if (workspace == null) {
      _showMessage(context, '작업 폴더를 먼저 선택하세요');
      return;
    }

    final result = await FilePicker.pickFiles(
      dialogTitle: '.txt 파일 선택',
      type: FileType.custom,
      allowedExtensions: const ['txt'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final txtPath = result.files.single.path;
    if (txtPath == null) return;

    final content = await File(txtPath).readAsString();
    final title = p.basenameWithoutExtension(txtPath);

    if (!context.mounted) return;
    await _runPreviewAndCommit(
      context: context,
      ref: ref,
      workspace: workspace,
      title: title,
      content: content,
    );
  }

  Future<void> importFromClipboard(BuildContext context, WidgetRef ref) async {
    final workspace = ref.read(settingsProvider).workspacePath;
    if (workspace == null) {
      _showMessage(context, '작업 폴더를 먼저 선택하세요');
      return;
    }

    final clip = await Clipboard.getData('text/plain');
    final content = clip?.text ?? '';

    final title = '클립보드_${DateTime.now().millisecondsSinceEpoch}';

    if (!context.mounted) return;
    await _runPreviewAndCommit(
      context: context,
      ref: ref,
      workspace: workspace,
      title: title,
      content: content,
    );
  }

  Future<void> _runPreviewAndCommit({
    required BuildContext context,
    required WidgetRef ref,
    required String workspace,
    required String title,
    required String content,
  }) async {
    if (!context.mounted) return;

    await ref.read(styleProvider.notifier).initialize();
    if (!context.mounted) return;

    final preview = await showImportPreviewDialog(
      context: context,
      ref: ref,
      title: title,
      content: content,
    );
    if (preview == null) return;

    final subPath = _uniqueSubPath(workspace, title);
    _subIo.writeFile(subPath, preview.sub);
    ref.read(workspaceProvider.notifier).rescan();
    ref.read(playbackProvider.notifier).loadImportedSub(subPath, preview.sub);

    if (context.mounted) {
      _showMessage(context, '가져오기 완료: ${preview.sub.title}');
    }
  }

  String _uniqueSubPath(String workspace, String title) {
    var candidate = p.join(workspace, '$title.sub');
    if (!File(candidate).existsSync()) return candidate;

    var index = 2;
    while (File(p.join(workspace, '${title}_$index.sub')).existsSync()) {
      index++;
    }
    return p.join(workspace, '${title}_$index.sub');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

final importFlowProvider = Provider<ImportFlow>((ref) => ImportFlow());
