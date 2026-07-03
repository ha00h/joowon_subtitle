import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';

class AppSettingsRepository {
  static const boxName = 'app_settings';

  static const workspacePathKey = 'workspacePath';
  static const workspaceBookmarkKey = 'workspaceBookmark';
  static const stylePathKey = 'stylePath';
  static const styleBookmarkKey = 'styleBookmark';
  static const outputBackgroundKey = 'outputBackground';
  static const outputMonitorIdKey = 'outputMonitorId';
  static const skippedUpdateVersionKey = 'skippedUpdateVersion';
  static const lastUpdateCheckAtKey = 'lastUpdateCheckAt';

  Box<String>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<String>(boxName);
  }

  void attachOpenBox() {
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<String>(boxName);
    }
  }

  Future<Box<String>> box() async {
    if (_box != null) return _box!;
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<String>(boxName);
      return _box!;
    }
    _box = await Hive.openBox<String>(boxName);
    return _box!;
  }

  AppSettings read() {
    attachOpenBox();
    return AppSettings(
      workspacePath: _box?.get(workspacePathKey),
      workspaceBookmark: _box?.get(workspaceBookmarkKey),
      stylePath: _box?.get(stylePathKey),
      styleBookmark: _box?.get(styleBookmarkKey),
      outputBackground:
          _box?.get(outputBackgroundKey) == 'transparent'
              ? OutputBackground.transparent
              : OutputBackground.black,
      outputMonitorId: _box?.get(outputMonitorIdKey),
    );
  }

  Future<void> writeWorkspacePath(String? path, {String? bookmark}) async {
    final b = await box();
    if (path == null) {
      await b.delete(workspacePathKey);
      await b.delete(workspaceBookmarkKey);
      return;
    }
    await b.put(workspacePathKey, path);
    if (bookmark != null && bookmark.isNotEmpty) {
      await b.put(workspaceBookmarkKey, bookmark);
    } else {
      await b.delete(workspaceBookmarkKey);
    }
  }

  Future<void> writeStylePath(String? path, {String? bookmark}) async {
    final b = await box();
    if (path == null) {
      await b.delete(stylePathKey);
      await b.delete(styleBookmarkKey);
      return;
    }
    await b.put(stylePathKey, path);
    if (bookmark != null && bookmark.isNotEmpty) {
      await b.put(styleBookmarkKey, bookmark);
    } else {
      await b.delete(styleBookmarkKey);
    }
  }

  Future<void> writeOutputBackground(OutputBackground bg) async {
    final b = await box();
    await b.put(
      outputBackgroundKey,
      bg == OutputBackground.transparent ? 'transparent' : 'black',
    );
  }

  Future<void> writeOutputMonitorId(String? id) async {
    final b = await box();
    if (id == null) {
      await b.delete(outputMonitorIdKey);
    } else {
      await b.put(outputMonitorIdKey, id);
    }
  }

  String? readSkippedUpdateVersion() {
    attachOpenBox();
    return _box?.get(skippedUpdateVersionKey);
  }

  Future<void> writeSkippedUpdateVersion(String version) async {
    final b = await box();
    await b.put(skippedUpdateVersionKey, version);
  }

  DateTime? readLastUpdateCheckAt() {
    attachOpenBox();
    final raw = _box?.get(lastUpdateCheckAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastUpdateCheckAt(DateTime at) async {
    final b = await box();
    await b.put(lastUpdateCheckAtKey, at.toIso8601String());
  }

  String? readBookmark(String key) {
    attachOpenBox();
    return _box?.get(key);
  }
}
