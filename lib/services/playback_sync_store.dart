import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/playback_sync_payload.dart';

/// 조작·송출 윈도우 간 공유 상태 (별도 Flutter 엔진 → JSON 파일)
///
/// Hive는 엔진마다 메모리 캐시가 분리되어 크로스 엔진 동기화에 적합하지 않음.
class PlaybackSyncStore {
  PlaybackSyncStore._();

  static const _fileName = 'playback_sync_state.json';
  static File? _stateFile;

  /// 테스트에서 고정 경로 사용
  @visibleForTesting
  static Directory? testDirectoryOverride;

  static Future<void> init() async {
    if (_stateFile != null) return;

    final Directory baseDir;
    if (testDirectoryOverride != null) {
      baseDir = testDirectoryOverride!;
    } else {
      baseDir = await getApplicationSupportDirectory();
    }

    final syncDir = Directory(p.join(baseDir.path, 'playback_sync'));
    if (!await syncDir.exists()) {
      await syncDir.create(recursive: true);
    }
    _stateFile = File(p.join(syncDir.path, _fileName));
  }

  static Future<void> write(PlaybackSyncPayload payload) async {
    await init();
    final file = _stateFile!;
    final rev = (readLatest()?.revision ?? 0) + 1;
    final envelope = {
      'revision': rev,
      'payload': payload.toJson(),
    };
    final encoded = jsonEncode(envelope);
    await file.writeAsString(encoded, flush: true);
  }

  /// 매 호출마다 디스크에서 읽어 다른 Flutter 엔진의 write를 반영한다.
  static ({PlaybackSyncPayload payload, int revision})? readLatest() {
    final file = _stateFile;
    if (file == null || !file.existsSync()) return null;

    try {
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final rev = raw['revision'];
      final payloadMap = raw['payload'];
      if (rev is! int || payloadMap is! Map<String, dynamic>) return null;

      final payload = PlaybackSyncPayload.fromJson(payloadMap);
      return (payload: payload, revision: rev);
    } catch (_) {
      return null;
    }
  }

  /// 테스트 간 static 상태 초기화
  @visibleForTesting
  static void testReset() {
    _stateFile = null;
    testDirectoryOverride = null;
  }
}
