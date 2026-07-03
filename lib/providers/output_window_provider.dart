import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/window_args.dart';
import '../providers/playback_provider.dart';
import '../providers/settings_provider.dart';
import '../services/monitor_service.dart';
import '../services/playback_sync_service.dart';
import '../services/window_setup.dart';

class OutputWindowState {
  const OutputWindowState({
    this.isOpen = false,
    this.isReconnecting = false,
    this.windowId,
    this.autoReconnectEnabled = true,
  });

  final bool isOpen;
  final bool isReconnecting;
  final String? windowId;
  final bool autoReconnectEnabled;

  OutputWindowState copyWith({
    bool? isOpen,
    bool? isReconnecting,
    String? windowId,
    bool? autoReconnectEnabled,
    bool clearWindowId = false,
  }) {
    return OutputWindowState(
      isOpen: isOpen ?? this.isOpen,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      windowId: clearWindowId ? null : (windowId ?? this.windowId),
      autoReconnectEnabled: autoReconnectEnabled ?? this.autoReconnectEnabled,
    );
  }
}

class OutputWindowNotifier extends Notifier<OutputWindowState> {
  WindowController? _controller;
  StreamSubscription<void>? _windowsSub;
  final _initCompleter = Completer<void>();

  @override
  OutputWindowState build() {
    ref.onDispose(_dispose);
    unawaited(_ensureInitialized());
    return const OutputWindowState();
  }

  Future<void> _ensureInitialized() async {
    await PlaybackSyncService.registerOperator(
      onOutputReady: () => unawaited(syncPlaybackIfOpen()),
    );

    _windowsSub ??= onWindowsChanged.listen((_) {
      unawaited(_handleWindowsChanged());
    });

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  Future<void> openOutputWindow() async {
    await _initCompleter.future;

    if (state.isOpen && _controller != null) {
      ref.read(playbackProvider.notifier).resyncToOutput();
      await syncPlaybackIfOpen();
      return;
    }

    await _closeStaleOutputWindows();

    final settings = ref.read(settingsProvider);
    final args = WindowArgs(
      type: WindowType.output,
      monitorId: settings.outputMonitorId,
      outputBackground: settings.outputBackground.name,
    );

    _controller = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: args.encode(),
      ),
    );
    PlaybackSyncService.attachOutput(_controller);

    state = state.copyWith(
      isOpen: true,
      windowId: _controller!.windowId,
      isReconnecting: false,
    );

    // 선택 슬라이드를 즉시 반영한 뒤, 송출 엔진 준비까지 재시도
    ref.read(playbackProvider.notifier).resyncToOutput();
    await syncPlaybackIfOpen();
    await _syncWithRetry();
  }

  Future<void> _closeStaleOutputWindows() async {
    final windows = await WindowController.getAll();
    for (final w in windows) {
      if (!WindowArgs.decode(w.arguments).isOutput) continue;
      try {
        await w.invokeMethod('window_close');
      } catch (_) {
        // ignore
      }
    }
    if (windows.any((w) => WindowArgs.decode(w.arguments).isOutput)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<void> _syncWithRetry() async {
    for (var i = 0; i < 20; i++) {
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      final ok = await syncPlaybackIfOpen();
      if (ok) return;
    }
    if (kDebugMode) {
      debugPrint('Output sync: all retries failed');
    }
  }

  Future<void> closeOutputWindow() async {
    await _closeOutputWindows(reconnectAfterClose: true);
  }

  /// 앱 종료 시 송출 창을 닫고 자동 재연결을 비활성화한다.
  Future<void> closeAllForShutdown() async {
    await _closeOutputWindows(reconnectAfterClose: false);
  }

  Future<void> _closeOutputWindows({required bool reconnectAfterClose}) async {
    state = state.copyWith(autoReconnectEnabled: false);

    final controllers = <WindowController>{};
    if (_controller != null) {
      controllers.add(_controller!);
    }

    try {
      final windows = await WindowController.getAll();
      for (final window in windows) {
        if (WindowArgs.decode(window.arguments).isOutput) {
          controllers.add(window);
        }
      }
    } catch (_) {
      // ignore
    }

    await Future.wait(
      controllers.map(_closeWindowWithTimeout),
      eagerError: false,
    );

    _controller = null;
    PlaybackSyncService.attachOutput(null);
    ref.read(playbackProvider.notifier).resetOutputModes();
    state = state.copyWith(
      isOpen: false,
      clearWindowId: true,
      autoReconnectEnabled: reconnectAfterClose,
    );

    if (reconnectAfterClose) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<void> _closeWindowWithTimeout(WindowController controller) async {
    try {
      await controller.closeWindow().timeout(const Duration(seconds: 2));
    } catch (_) {
      // ignore — 종료 흐름은 계속 진행
    }
  }

  Future<void> reopenOnMonitorChange() async {
    if (!state.isOpen) return;
    await _controller?.closeWindow();
    _controller = null;
    state = state.copyWith(isOpen: false, clearWindowId: true);
    await openOutputWindow();
  }

  Future<bool> syncPlaybackIfOpen() async {
    if (!state.isOpen) return false;

    return PlaybackSyncService.push(
      ref.read(playbackProvider.notifier).buildSyncPayload(),
    );
  }

  Future<void> _handleWindowsChanged() async {
    final windows = await WindowController.getAll();
    final outputWindows = windows.where((w) {
      return WindowArgs.decode(w.arguments).isOutput;
    }).toList();

    if (outputWindows.isEmpty && state.isOpen && state.autoReconnectEnabled) {
      await _autoReconnect();
      return;
    }

    if (outputWindows.isNotEmpty) {
      _controller = outputWindows.first;
      PlaybackSyncService.attachOutput(_controller);
      state = state.copyWith(
        isOpen: true,
        windowId: _controller!.windowId,
        isReconnecting: false,
      );
    }
  }

  Future<void> _autoReconnect() async {
    if (state.isReconnecting) return;
    state = state.copyWith(
      isReconnecting: true,
      isOpen: false,
      clearWindowId: true,
    );
    _controller = null;

    ref.read(playbackProvider.notifier).setBlankForReconnect();

    await Future<void>.delayed(const Duration(milliseconds: 400));
    await openOutputWindow();
    state = state.copyWith(isReconnecting: false);
  }

  void _dispose() {
    _windowsSub?.cancel();
    unawaited(PlaybackSyncService.disposeOperator());
  }
}

final outputWindowProvider =
    NotifierProvider<OutputWindowNotifier, OutputWindowState>(
  OutputWindowNotifier.new,
);

final monitorServiceProvider = Provider((ref) => MonitorService());

final monitorsProvider = FutureProvider<MonitorListResult>((ref) async {
  return ref.read(monitorServiceProvider).listMonitors();
});
