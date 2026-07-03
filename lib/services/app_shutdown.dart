import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/output_window_provider.dart';

var _appClosing = false;

/// 조작 창·송출 창을 함께 종료한다.
Future<void> shutdownApplication(WidgetRef ref) async {
  if (_appClosing) return;
  _appClosing = true;

  try {
    await ref
        .read(outputWindowProvider.notifier)
        .closeAllForShutdown()
        .timeout(const Duration(seconds: 3), onTimeout: () {});
  } catch (_) {
    // 송출 창 종료에 실패해도 조작 창은 닫는다.
  } finally {
    await windowManager.setPreventClose(false);
    if (Platform.isWindows) {
      await windowManager.destroy();
    } else {
      await windowManager.close();
    }
  }
}
