import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:joowon_subtitle/models/playback_sync_payload.dart';
import 'package:joowon_subtitle/models/resolved_text_style.dart';
import 'package:joowon_subtitle/models/slide_elements.dart';
import 'package:joowon_subtitle/models/style_file.dart';
import 'package:joowon_subtitle/providers/order_provider.dart';
import 'package:joowon_subtitle/providers/output_playback_provider.dart';
import 'package:joowon_subtitle/providers/playback_provider.dart';
import 'package:joowon_subtitle/providers/settings_provider.dart';
import 'package:joowon_subtitle/providers/style_provider.dart';
import 'package:joowon_subtitle/services/playback_sync_store.dart';
import 'package:joowon_subtitle/services/sub_io.dart';
import 'package:path/path.dart' as p;

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _TestStyleNotifier extends StyleNotifier {
  @override
  StyleState build() => StyleState(
        style: StyleFile.defaultStyle,
        initialized: true,
      );
}

/// VERIFICATION.md Level 3
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory hymnsDir;
  late SubIo subIo;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('mvp_integration_');
    hymnsDir = Directory(p.join(tempDir.path, 'hymns'))..createSync();
    Hive.init(tempDir.path);
    await Hive.openBox<String>('service_orders');
    await Hive.openBox<String>('app_settings');
    PlaybackSyncStore.testDirectoryOverride = tempDir;
    await PlaybackSyncStore.init();
  });

  tearDownAll(() async {
    PlaybackSyncStore.testReset();
    await Hive.close();
    if (tempDir.existsSync()) {
      for (var attempt = 0; attempt < 10; attempt++) {
        try {
          tempDir.deleteSync(recursive: true);
          break;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  });

  setUp(() async {
    await Hive.box<String>('service_orders').clear();
    await Hive.box<String>('app_settings').clear();

    subIo = SubIo();
    File(p.join(hymnsDir.path, 'sample.txt')).writeAsStringSync(
      File('test/fixtures/sample.txt').readAsStringSync(),
    );
    if (File('dev/hymns/주일예배.style').existsSync()) {
      File(p.join(hymnsDir.path, '주일예배.style')).writeAsStringSync(
        File('dev/hymns/주일예배.style').readAsStringSync(),
      );
    }
  });

  ProviderContainer makeContainer({bool useRealSettings = false}) {
    return ProviderContainer(
      overrides: [
        subIoProvider.overrideWithValue(subIo),
        if (!useRealSettings) ...[
          settingsProvider.overrideWith(_TestSettingsNotifier.new),
          styleProvider.overrideWith(_TestStyleNotifier.new),
        ],
      ],
    );
  }

  Future<void> writeSyncFromPlayback(ProviderContainer c) async {
    final pb = c.read(playbackProvider);
    final style = c.read(activeStyleFileProvider);
    await PlaybackSyncStore.write(
      PlaybackSyncPayload(
        sub: pb.currentSub,
        slideIndex: pb.slideIndex,
        isBlank: pb.isBlack,
        style: style,
      ),
    );
  }

  group('시나리오 1 — 최초 설정 (저장·재로드)', () {
    test('작업 폴더·style·배경 설정 Hive 유지', () async {
      final c = makeContainer(useRealSettings: true);
      final stylePath = p.join(hymnsDir.path, '주일예배.style');

      await c.read(settingsProvider.notifier).setWorkspacePath(hymnsDir.path);
      if (File(stylePath).existsSync()) {
        await c.read(settingsProvider.notifier).setStylePath(stylePath);
      }
      await c.read(settingsProvider.notifier).setOutputBackground(
            OutputBackground.transparent,
          );

      expect(c.read(settingsProvider).workspacePath, hymnsDir.path);
      expect(
        c.read(settingsProvider).outputBackground,
        OutputBackground.transparent,
      );
      if (File(stylePath).existsSync()) {
        expect(c.read(settingsProvider).stylePath, stylePath);
      }

      c.dispose();
    });
  });

  group('시나리오 2 — txt → sub → 송출 동기화', () {
    test('txt 가져오기·슬라이드 넘김·PlaybackSyncStore 반영', () async {
      final c = makeContainer();
      final txtPath = p.join(hymnsDir.path, 'sample.txt');
      final subPath = p.setExtension(txtPath, '.sub');

      final sub = subIo.fromTxt(
        content: File(txtPath).readAsStringSync(),
        title: p.basenameWithoutExtension(txtPath),
      );
      subIo.writeFile(subPath, sub);
      expect(File(subPath).existsSync(), isTrue);

      c.read(playbackProvider.notifier).loadSub(subPath);
      expect(c.read(playbackProvider).slideIndex, 0);
      expect(c.read(playbackProvider).currentSub!.slides.length, 3);

      c.read(playbackProvider.notifier).nextSlide();
      c.read(playbackProvider.notifier).nextSlide();
      expect(c.read(playbackProvider).slideIndex, 2);

      await writeSyncFromPlayback(c);

      final latest = PlaybackSyncStore.readLatest();
      expect(latest, isNotNull);
      expect(latest!.payload.slideIndex, 2);
      expect(latest.payload.isBlank, isFalse);

      final output = OutputPlaybackState(
        sub: latest.payload.sub,
        slideIndex: latest.payload.slideIndex,
        isBlank: latest.payload.isBlank,
        payload: latest.payload,
      );
      expect(output.currentSlide?.elements.first.lines?.first, '할렐루야');

      c.dispose();
    });
  });

  group('시나리오 3 — 예배 순서', () {
    test('순서 구성·Page Down(다음 곡)·Hive 유지', () async {
      final subAPath = p.join(hymnsDir.path, 'a.sub');
      final subBPath = p.join(hymnsDir.path, 'b.sub');
      final subCPath = p.join(hymnsDir.path, 'c.sub');
      subIo.writeFile(
        subAPath,
        subIo.fromTxt(content: 'A1\n\nA2', title: '곡A'),
      );
      subIo.writeFile(
        subBPath,
        subIo.fromTxt(content: 'B1\n\nB2', title: '곡B'),
      );
      subIo.writeFile(
        subCPath,
        subIo.fromTxt(content: 'C1', title: '곡C'),
      );

      final c = makeContainer();
      await c.read(orderRepositoryProvider).init();
      c.read(orderProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await c.read(orderProvider.notifier).createOrder('주일예배');
      await c.read(orderProvider.notifier).addItem(subAPath, '곡A');
      await c.read(orderProvider.notifier).addItem(subBPath, '곡B');
      await c.read(orderProvider.notifier).addItem(subCPath, '곡C');

      expect(c.read(orderProvider).activeOrder!.items.length, 3);

      c.read(playbackProvider.notifier).loadSub(subAPath);
      c.read(playbackProvider.notifier).nextHymn();

      expect(c.read(orderProvider).activeItemIndex, 1);
      expect(c.read(playbackProvider).currentPath, subBPath);
      expect(c.read(playbackProvider).slideIndex, 0);

      final c2 = makeContainer();
      for (var i = 0; i < 20; i++) {
        if (c2.read(orderProvider).orders.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(c2.read(orderProvider).orders.single.items.length, 3);
      expect(c2.read(orderProvider).activeOrderId, c.read(orderProvider).activeOrderId);
      expect(c2.read(orderProvider).activeItemIndex, 1);

      c.dispose();
      c2.dispose();
    });
  });

  group('시나리오 4 — 편집·Undo·자동 저장', () {
    test('텍스트 수정·Undo·파일 round-trip·override', () async {
      final subPath = p.join(hymnsDir.path, 'edit.sub');
      final sub = subIo.fromTxt(content: '원본\n\n두번째', title: '편집곡');
      subIo.writeFile(subPath, sub);

      final c = makeContainer();
      c.read(playbackProvider.notifier).loadSub(subPath);

      final original = c.read(playbackProvider).currentSub!;
      final elId = original.slides.first.elements.first.id;
      final updatedLines = ['수정된 가사'];
      final elements = original.slides.first.elements
          .map(
            (e) => e.id == elId
                ? e.copyWith(lines: updatedLines, fontSize: 99)
                : e,
          )
          .toList();
      final edited = original.copyWith(
        slides: [Slide(elements: elements), ...original.slides.skip(1)],
      );

      c.read(playbackProvider.notifier).updateSub(edited);
      expect(
        c.read(playbackProvider).currentSub!.slides.first.elements.first.lines,
        updatedLines,
      );

      c.read(playbackProvider.notifier).undo();
      expect(
        c.read(playbackProvider).currentSub!.slides.first.elements.first.lines,
        ['원본'],
      );

      c.read(playbackProvider.notifier).updateSub(edited);
      final reloaded = subIo.readFile(subPath);
      expect(reloaded.slides.first.elements.first.lines, updatedLines);

      final resolver = StyleResolver(styleFile: StyleFile.defaultStyle);
      final resolved = resolver.resolveText(
        reloaded.slides.first.elements.first,
      );
      expect(resolved.fontSize, 99);

      c.dispose();
    });
  });

  group('시나리오 5 — B blank', () {
    test('B 토글 시 송출만 blank, 슬라이드 인덱스 유지', () async {
      final c = makeContainer();
      final subPath = p.join(hymnsDir.path, 'blank.sub');
      subIo.writeFile(
        subPath,
        subIo.fromTxt(content: '가사\n\n다음', title: 'blank'),
      );
      c.read(playbackProvider.notifier).loadSub(subPath);
      c.read(playbackProvider.notifier).goToSlide(1);

      c.read(playbackProvider.notifier).toggleBlank();
      expect(c.read(playbackProvider).isBlack, isTrue);
      expect(c.read(playbackProvider).slideIndex, 1);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await writeSyncFromPlayback(c);
      final sync = PlaybackSyncStore.readLatest();
      expect(sync, isNotNull);
      expect(sync!.payload.isBlank, isTrue);
      expect(sync.payload.slideIndex, 1);

      c.read(playbackProvider.notifier).toggleBlank();
      expect(c.read(playbackProvider).isBlack, isFalse);
      expect(c.read(playbackProvider).slideIndex, 1);

      c.dispose();
    });
  });
}
