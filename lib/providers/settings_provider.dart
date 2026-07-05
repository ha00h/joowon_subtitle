import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../repositories/app_settings_repository.dart';
import '../services/security_scoped_access.dart';

export '../models/app_settings.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository();
});

class SettingsNotifier extends Notifier<AppSettings> {
  late AppSettingsRepository _repo;

  @override
  AppSettings build() {
    _repo = ref.read(appSettingsRepositoryProvider);
    if (Hive.isBoxOpen(AppSettingsRepository.boxName)) {
      _repo.attachOpenBox();
      return _repo.read();
    }
    unawaited(_load());
    return const AppSettings();
  }

  Future<void> _load() async {
    await _repo.init();
    state = _repo.read();
  }

  Future<void> restoreSecurityScopedAccess() async {
    if (!Platform.isMacOS) return;

    await _repo.init();
    var workspacePath = state.workspacePath;
    var stylePath = state.stylePath;

    final workspaceBookmark =
        _repo.readBookmark(AppSettingsRepository.workspaceBookmarkKey);
    if (workspaceBookmark != null && workspaceBookmark.isNotEmpty) {
      final restored =
          await SecurityScopedAccess.restoreBookmark(workspaceBookmark);
      if (restored != null) {
        workspacePath = restored;
      }
    }

    final styleBookmark =
        _repo.readBookmark(AppSettingsRepository.styleBookmarkKey);
    if (styleBookmark != null && styleBookmark.isNotEmpty) {
      final restored = await SecurityScopedAccess.restoreBookmark(styleBookmark);
      if (restored != null) {
        stylePath = restored;
      }
    }

    state = state.copyWith(
      workspacePath: workspacePath,
      stylePath: stylePath,
    );
  }

  Future<void> setWorkspacePath(String? path, {String? bookmark}) async {
    await _repo.writeWorkspacePath(path, bookmark: bookmark);
    state = state.copyWith(
      workspacePath: path,
      workspaceBookmark: bookmark,
      clearWorkspacePath: path == null,
      clearWorkspaceBookmark:
          path == null || bookmark == null || bookmark.isEmpty,
    );
  }

  Future<void> setStylePath(String? path, {String? bookmark}) async {
    await _repo.writeStylePath(path, bookmark: bookmark);
    state = state.copyWith(
      stylePath: path,
      styleBookmark: bookmark,
      clearStylePath: path == null,
      clearStyleBookmark:
          path == null || bookmark == null || bookmark.isEmpty,
    );
  }

  Future<void> setOutputBackground(OutputBackground bg) async {
    await _repo.writeOutputBackground(bg);
    state = state.copyWith(outputBackground: bg);
  }

  Future<void> setOutputMonitorId(String? id) async {
    await _repo.writeOutputMonitorId(id);
    state = state.copyWith(
      outputMonitorId: id,
      clearOutputMonitorId: id == null,
    );
  }

  Future<void> setOperatorPanelWidth(double width) async {
    final clamped = width.clamp(
      AppSettings.minOperatorPanelWidth,
      AppSettings.maxOperatorPanelWidth,
    );
    await _repo.writeOperatorPanelWidth(clamped);
    state = state.copyWith(operatorPanelWidth: clamped);
  }

  Future<void> setOperatorSearchListRatio(double ratio) async {
    final clamped = ratio.clamp(
      AppSettings.minOperatorSearchListRatio,
      AppSettings.maxOperatorSearchListRatio,
    );
    await _repo.writeOperatorSearchListRatio(clamped);
    state = state.copyWith(operatorSearchListRatio: clamped);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
