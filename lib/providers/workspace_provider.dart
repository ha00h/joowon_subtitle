import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../services/sub_io.dart';
import '../services/workspace_file_ops.dart' as file_ops;
import '../services/workspace_scanner.dart';
import 'order_provider.dart';
import 'playback_provider.dart';
import 'settings_provider.dart';

class WorkspaceState {
  const WorkspaceState({
    this.rootPath,
    this.entries = const [],
    this.query = '',
  });

  final String? rootPath;
  final List<SubFileEntry> entries;
  final String query;

  List<SubFileEntry> get filteredEntries {
    if (rootPath == null) return const [];
    return WorkspaceScanner().search(entries, query);
  }

  WorkspaceState copyWith({
    String? rootPath,
    List<SubFileEntry>? entries,
    String? query,
  }) {
    return WorkspaceState(
      rootPath: rootPath ?? this.rootPath,
      entries: entries ?? this.entries,
      query: query ?? this.query,
    );
  }
}

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  final _scanner = WorkspaceScanner();
  final _subIo = SubIo();

  @override
  WorkspaceState build() {
    ref.listen<String?>(
      settingsProvider.select((s) => s.workspacePath),
      (previous, next) => _applyWorkspacePath(next),
    );

    final initialPath = ref.read(settingsProvider).workspacePath;
    if (initialPath != null) {
      scheduleMicrotask(() => _applyWorkspacePath(initialPath));
    }

    return const WorkspaceState();
  }

  void _applyWorkspacePath(String? path) {
    if (path == null) {
      state = const WorkspaceState();
      return;
    }
    final entries = _scanner.scanSubFiles(path);
    state = WorkspaceState(
      rootPath: path,
      entries: entries,
      query: state.query,
    );
  }

  /// 저장된 설정 경로로 작업 폴더를 다시 스캔합니다 (앱 시작·보안 스코프 복원 후).
  void reloadFromSettings() {
    final path = ref.read(settingsProvider).workspacePath;
    if (path == null) {
      state = const WorkspaceState();
      return;
    }
    final entries = _scanner.scanSubFiles(path);
    state = WorkspaceState(
      rootPath: path,
      entries: entries,
      query: state.query,
    );
  }

  void setRootPath(String? path) {
    if (path == null) {
      state = const WorkspaceState();
      return;
    }
    final entries = _scanner.scanSubFiles(path);
    state = WorkspaceState(rootPath: path, entries: entries);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void rescan() {
    final path = state.rootPath;
    if (path == null) return;
    state = state.copyWith(entries: _scanner.scanSubFiles(path));
  }

  Future<String?> renameSubFile({
    required String oldPath,
    required String newBaseName,
  }) async {
    try {
      final newPath = await file_ops.renameSubFile(
        oldPath: oldPath,
        newBaseName: newBaseName,
      );
      var sub = _subIo.readFile(newPath);
      final newTitle = file_ops.titleFromSubBaseName(
        p.basenameWithoutExtension(newPath),
      );
      if (newTitle.isNotEmpty && sub.title != newTitle) {
        sub = sub.copyWith(title: newTitle);
        _subIo.writeFile(newPath, sub);
      }
      await ref
          .read(orderProvider.notifier)
          .renameFileReferences(oldPath, newPath, sub.title);
      ref.read(playbackProvider.notifier).replacePathIfMatches(
            oldPath,
            newPath,
            newTitle: sub.title,
          );
      rescan();
      return newPath;
    } on FileSystemException catch (e) {
      throw FileSystemException(e.message, e.path);
    } on FormatException catch (e) {
      throw FormatException(e.message);
    }
  }
}

final workspaceProvider =
    NotifierProvider<WorkspaceNotifier, WorkspaceState>(WorkspaceNotifier.new);
