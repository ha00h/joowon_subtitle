import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/app_branding.dart';
import 'constants/operator_theme.dart';
import 'models/playback_sync_payload.dart';
import 'models/window_args.dart';
import 'providers/output_playback_provider.dart';
import 'repositories/app_settings_repository.dart';
import 'repositories/order_repository.dart';
import 'services/playback_sync_store.dart';
import 'services/playback_sync_service.dart';
import 'services/security_scoped_access.dart';
import 'services/window_setup.dart';
import 'windows/operator/operator_screen.dart';
import 'windows/output/output_screen.dart';
import 'widgets/common/operator_window_lifecycle.dart';

Future<void> bootstrap({required bool isOutput}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (isOutput) {
    // 송출 엔진은 PlaybackSync만 필요. Hive 박스는 조작 엔진과 lock 충돌.
    await PlaybackSyncStore.init();
    return;
  }

  await OrderRepository().init();
  await AppSettingsRepository().init();
  await _restorePersistedSecurityBookmarks();
  await PlaybackSyncStore.init();
}

Future<void> _restorePersistedSecurityBookmarks() async {
  if (!Platform.isMacOS) return;

  final repo = AppSettingsRepository()..attachOpenBox();
  final workspaceBookmark =
      repo.readBookmark(AppSettingsRepository.workspaceBookmarkKey);
  if (workspaceBookmark != null && workspaceBookmark.isNotEmpty) {
    await SecurityScopedAccess.restoreBookmark(workspaceBookmark);
  }

  final styleBookmark =
      repo.readBookmark(AppSettingsRepository.styleBookmarkKey);
  if (styleBookmark != null && styleBookmark.isNotEmpty) {
    await SecurityScopedAccess.restoreBookmark(styleBookmark);
  }
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await WindowController.fromCurrentEngine();
  final windowArgs = WindowArgs.decode(controller.arguments);

  await bootstrap(isOutput: windowArgs.isOutput);

  if (windowArgs.isOutput) {
    await _runOutputWindow(windowArgs);
  } else {
    await _runOperatorWindow();
  }
}

Future<void> _runOperatorWindow() async {
  await configureOperatorWindow();
  await initWindowControllerHandlers();
  runApp(const ProviderScope(child: JoowonSubtitleApp()));
}

Future<void> _runOutputWindow(WindowArgs windowArgs) async {
  final transparent = windowArgs.outputBackground == 'transparent';

  final container = ProviderContainer();

  await initWindowControllerHandlers(
    extraHandler: (call) => _handleOutputPlaybackSync(call, container),
  );

  await configureOutputWindow(
    args: windowArgs,
    transparent: transparent,
  );

  PlaybackSyncService.bootstrapOutput(
    (payload) => _applyOutputSync(container, payload),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OutputApp(),
    ),
  );
}

Future<Object?> _handleOutputPlaybackSync(
  MethodCall call,
  ProviderContainer container,
) async {
  if (call.method != 'updatePlayback') return windowHandlerNotHandled;
  final map = Map<String, dynamic>.from(call.arguments as Map);
  _applyOutputSync(container, PlaybackSyncPayload.fromJson(map));
  return null;
}

void _applyOutputSync(ProviderContainer container, PlaybackSyncPayload payload) {
  void apply() {
    container.read(outputPlaybackProvider.notifier).applySync(payload);
  }

  final binding = WidgetsBinding.instance;
  if (binding.schedulerPhase == SchedulerPhase.idle) {
    apply();
  } else {
    binding.addPostFrameCallback((_) => apply());
  }
}

class JoowonSubtitleApp extends StatelessWidget {
  const JoowonSubtitleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppDisplayName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
          surface: OperatorTheme.surface,
        ),
        scaffoldBackgroundColor: OperatorTheme.background,
        useMaterial3: true,
      ),
      home: const OperatorWindowLifecycle(child: OperatorScreen()),
    );
  }
}
