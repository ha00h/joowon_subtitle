import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workspace_scanner.dart';
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
    if (query.trim().isEmpty) return entries;
    final q = query.toLowerCase();
    return entries
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.relativePath.toLowerCase().contains(q),
        )
        .toList();
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
    if (path == state.rootPath && state.entries.isNotEmpty) return;
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
}

final workspaceProvider =
    NotifierProvider<WorkspaceNotifier, WorkspaceState>(WorkspaceNotifier.new);
