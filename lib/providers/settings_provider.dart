import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/security_scoped_access.dart';

enum OutputBackground { black, transparent }

class AppSettings {
  const AppSettings({
    this.workspacePath,
    this.workspaceBookmark,
    this.stylePath,
    this.styleBookmark,
    this.outputBackground = OutputBackground.black,
    this.outputMonitorId,
  });

  final String? workspacePath;
  final String? workspaceBookmark;
  final String? stylePath;
  final String? styleBookmark;
  final OutputBackground outputBackground;
  final String? outputMonitorId;

  AppSettings copyWith({
    String? workspacePath,
    String? workspaceBookmark,
    String? stylePath,
    String? styleBookmark,
    OutputBackground? outputBackground,
    String? outputMonitorId,
    bool clearWorkspacePath = false,
    bool clearWorkspaceBookmark = false,
    bool clearStylePath = false,
    bool clearStyleBookmark = false,
    bool clearOutputMonitorId = false,
  }) {
    return AppSettings(
      workspacePath:
          clearWorkspacePath ? null : (workspacePath ?? this.workspacePath),
      workspaceBookmark: clearWorkspaceBookmark
          ? null
          : (workspaceBookmark ?? this.workspaceBookmark),
      stylePath: clearStylePath ? null : (stylePath ?? this.stylePath),
      styleBookmark:
          clearStyleBookmark ? null : (styleBookmark ?? this.styleBookmark),
      outputBackground: outputBackground ?? this.outputBackground,
      outputMonitorId: clearOutputMonitorId
          ? null
          : (outputMonitorId ?? this.outputMonitorId),
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _boxName = 'app_settings';
  Box<String>? _box;

  @override
  AppSettings build() {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<String>(_boxName);
      return _readFromBox();
    }
    unawaited(_load());
    return const AppSettings();
  }

  AppSettings _readFromBox() {
    return AppSettings(
      workspacePath: _box?.get('workspacePath'),
      workspaceBookmark: _box?.get('workspaceBookmark'),
      stylePath: _box?.get('stylePath'),
      styleBookmark: _box?.get('styleBookmark'),
      outputBackground: _box?.get('outputBackground') == 'transparent'
          ? OutputBackground.transparent
          : OutputBackground.black,
      outputMonitorId: _box?.get('outputMonitorId'),
    );
  }

  Future<void> _load() async {
    _box ??= await Hive.openBox<String>(_boxName);
    state = _readFromBox();
  }

  Future<void> restoreSecurityScopedAccess() async {
    if (!Platform.isMacOS) return;

    _box ??= await Hive.openBox<String>(_boxName);
    var workspacePath = state.workspacePath;
    var stylePath = state.stylePath;

    final workspaceBookmark = _box?.get('workspaceBookmark');
    if (workspaceBookmark != null && workspaceBookmark.isNotEmpty) {
      final restored =
          await SecurityScopedAccess.restoreBookmark(workspaceBookmark);
      if (restored != null) {
        workspacePath = restored;
      }
    }

    final styleBookmark = _box?.get('styleBookmark');
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
    _box ??= await Hive.openBox<String>(_boxName);
    if (path == null) {
      await _box?.delete('workspacePath');
      await _box?.delete('workspaceBookmark');
    } else {
      await _box?.put('workspacePath', path);
      if (bookmark != null && bookmark.isNotEmpty) {
        await _box?.put('workspaceBookmark', bookmark);
      } else {
        await _box?.delete('workspaceBookmark');
      }
    }
    state = state.copyWith(
      workspacePath: path,
      workspaceBookmark: bookmark,
      clearWorkspacePath: path == null,
      clearWorkspaceBookmark:
          path == null || bookmark == null || bookmark.isEmpty,
    );
  }

  Future<void> setStylePath(String? path, {String? bookmark}) async {
    _box ??= await Hive.openBox<String>(_boxName);
    if (path == null) {
      await _box?.delete('stylePath');
      await _box?.delete('styleBookmark');
    } else {
      await _box?.put('stylePath', path);
      if (bookmark != null && bookmark.isNotEmpty) {
        await _box?.put('styleBookmark', bookmark);
      } else {
        await _box?.delete('styleBookmark');
      }
    }
    state = state.copyWith(
      stylePath: path,
      styleBookmark: bookmark,
      clearStylePath: path == null,
      clearStyleBookmark:
          path == null || bookmark == null || bookmark.isEmpty,
    );
  }

  Future<void> setOutputBackground(OutputBackground bg) async {
    _box ??= await Hive.openBox<String>(_boxName);
    await _box?.put(
      'outputBackground',
      bg == OutputBackground.transparent ? 'transparent' : 'black',
    );
    state = state.copyWith(outputBackground: bg);
  }

  Future<void> setOutputMonitorId(String? id) async {
    _box ??= await Hive.openBox<String>(_boxName);
    if (id == null) {
      await _box?.delete('outputMonitorId');
    } else {
      await _box?.put('outputMonitorId', id);
    }
    state = state.copyWith(
      outputMonitorId: id,
      clearOutputMonitorId: id == null,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
