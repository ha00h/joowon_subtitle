import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../constants/app_branding.dart';
import '../constants/operator_theme.dart';
import '../models/window_args.dart';
import '../services/monitor_service.dart';

/// extraHandler가 처리하지 않음을 나타내는 sentinel
const windowHandlerNotHandled = Object();

/// 송출 윈도우 native 배치 (window_manager)
Future<void> configureOutputWindow({
  required WindowArgs args,
  required bool transparent,
}) async {
  await windowManager.ensureInitialized();

  final monitorService = MonitorService();
  final bounds = await monitorService.boundsForMonitorId(args.monitorId);

  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: Size(bounds.width, bounds.height),
      backgroundColor: transparent ? Colors.transparent : Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: false,
    ),
    () async {},
  );

  await windowManager.setBounds(bounds);
  await windowManager.setTitle(kAppOutputWindowTitle);
  await windowManager.setFullScreen(true);
  await windowManager.show();
}

/// 조작 윈도우 초기 설정
Future<void> configureOperatorWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1440, 900),
      center: true,
      backgroundColor: OperatorTheme.background,
      titleBarStyle: TitleBarStyle.normal,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
  await windowManager.setTitle(kAppDisplayName);
}

/// WindowController 커스텀 메서드 (close, updatePlayback 등)
Future<void> initWindowControllerHandlers({
  Future<dynamic> Function(MethodCall call)? extraHandler,
}) async {
  final controller = await WindowController.fromCurrentEngine();
  await controller.setWindowMethodHandler((call) async {
    if (extraHandler != null) {
      final handled = await extraHandler(call);
      if (handled != windowHandlerNotHandled) return handled;
    }
    switch (call.method) {
      case 'window_close':
        await windowManager.close();
      case 'window_center':
        await windowManager.center();
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  });
}

extension WindowControllerOps on WindowController {
  Future<void> closeWindow() => invokeMethod('window_close');
}
