import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers/output_window_provider.dart';

/// 조작 창이 닫힐 때 송출 창도 함께 종료한다.
class OperatorWindowLifecycle extends ConsumerStatefulWidget {
  const OperatorWindowLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OperatorWindowLifecycle> createState() =>
      _OperatorWindowLifecycleState();
}

class _OperatorWindowLifecycleState extends ConsumerState<OperatorWindowLifecycle>
    with WindowListener {
  var _closing = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(windowManager.setPreventClose(true));
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(_closeAllWindows());
  }

  Future<void> _closeAllWindows() async {
    if (_closing) return;
    _closing = true;

    try {
      if (ref.read(outputWindowProvider).isOpen) {
        await ref.read(outputWindowProvider.notifier).closeOutputWindow();
      }
    } finally {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
