import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:joowon_subtitle/main.dart';
import 'package:joowon_subtitle/services/playback_sync_store.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('joowon_hive_test');
    Hive.init(dir.path);
    await Hive.openBox<String>('service_orders');
    await Hive.openBox<String>('app_settings');
    PlaybackSyncStore.testDirectoryOverride = dir;
    await PlaybackSyncStore.init();
  });

  testWidgets('M0: app shows 16:9 canvas area', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: JoowonSubtitleApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('찬양 검색'), findsOneWidget);
    expect(find.text('작업 폴더를 선택하세요'), findsOneWidget);
  });
}
