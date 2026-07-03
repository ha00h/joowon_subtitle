import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

import '../models/playback_sync_payload.dart';
import 'playback_sync_store.dart';

typedef PlaybackSyncHandler = void Function(PlaybackSyncPayload payload);
typedef OutputReadyHandler = void Function();

/// 조작 ↔ 송출 윈도우 간 PlaybackState 동기화
///
/// - 공유 파일([PlaybackSyncStore]) + 송출 창 직접 호출(`updatePlayback`)
/// - `WindowMethodChannel`은 조작 엔진 1개만 등록 (Off→On 재시작 시 채널 한도 회피)
class PlaybackSyncService {
  PlaybackSyncService._();

  static const _channel = WindowMethodChannel(
    'joowon/playback_sync',
    mode: ChannelMode.bidirectional,
  );

  static WindowController? _outputController;
  static bool _operatorRegistered = false;
  static OutputReadyHandler? _onOutputReady;

  static void attachOutput(WindowController? controller) {
    _outputController = controller;
  }

  static Future<void> registerOperator({
    required OutputReadyHandler onOutputReady,
  }) async {
    _onOutputReady = onOutputReady;
    if (_operatorRegistered) return;
    try {
      await _channel.setMethodCallHandler((call) async {
        if (call.method == 'ready') {
          _onOutputReady?.call();
        }
      });
      _operatorRegistered = true;
    } on WindowChannelException catch (e) {
      if (kDebugMode) {
        debugPrint('PlaybackSync operator channel skipped: ${e.code}');
      }
    }
  }

  /// 송출 엔진 초기화 — 채널 등록 없이 저장소 스냅샷만 적용
  static void bootstrapOutput(PlaybackSyncHandler onUpdate) {
    final latest = PlaybackSyncStore.readLatest();
    if (latest != null) {
      onUpdate(latest.payload);
    }
  }

  static Future<bool> push(PlaybackSyncPayload payload) async {
    await PlaybackSyncStore.write(payload);

    final controller = _outputController;
    if (controller == null) return true;

    try {
      await controller.invokeMethod('updatePlayback', payload.toJson());
    } on WindowChannelException catch (e) {
      if (kDebugMode) {
        debugPrint('PlaybackSync direct: ${e.code}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PlaybackSync direct: $e');
      }
    }

    return true;
  }

  static Future<void> disposeOperator() async {
    try {
      await _channel.setMethodCallHandler(null);
    } catch (_) {
      // ignore
    }
    _operatorRegistered = false;
    _onOutputReady = null;
  }
}
