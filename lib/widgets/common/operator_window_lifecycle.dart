import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../services/app_shutdown.dart';

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
    unawaited(shutdownApplication(ref));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
