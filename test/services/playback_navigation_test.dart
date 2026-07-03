import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:joowon_subtitle/models/style_file.dart';
import 'package:joowon_subtitle/providers/order_provider.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late SubIo subIo;
  late String hymnA;
  late String hymnB;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('playback_nav_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>('service_orders');
    await Hive.openBox<String>('app_settings');
    PlaybackSyncStore.testDirectoryOverride = tempDir;
    await PlaybackSyncStore.init();
  });

  setUp(() async {
    await Hive.box<String>('service_orders').clear();
    await Hive.box<String>('app_settings').clear();

    subIo = SubIo();
    final txtA = File('test/fixtures/sample.txt').readAsStringSync();
    final subA = subIo.fromTxt(content: txtA, title: '곡A');
    hymnA = p.join(tempDir.path, 'a.sub');
    subIo.writeFile(hymnA, subA);

    final subB = subIo.fromTxt(content: '첫 슬라이드\n\n둘째 슬라이드', title: '곡B');
    hymnB = p.join(tempDir.path, 'b.sub');
    subIo.writeFile(hymnB, subB);
  });

  tearDownAll(() async {
    PlaybackSyncStore.testReset();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        subIoProvider.overrideWithValue(subIo),
        settingsProvider.overrideWith(_TestSettingsNotifier.new),
        styleProvider.overrideWith(_TestStyleNotifier.new),
      ],
    );
  }

  Future<void> setupOrder(ProviderContainer c) async {
    await c.read(orderRepositoryProvider).init();
    c.read(orderProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await c.read(orderProvider.notifier).createOrder('예배');
    await c.read(orderProvider.notifier).addItem(hymnA, '곡A');
    await c.read(orderProvider.notifier).addItem(hymnB, '곡B');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    c.read(playbackProvider.notifier).loadSub(hymnA);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  group('Playback navigation (VERIFICATION P-*)', () {
    test('P-01: next mid slide increments slideIndex', () {
      final c = makeContainer();
      c.read(playbackProvider.notifier).loadSub(hymnA);

      c.read(playbackProvider.notifier).nextSlide();
      expect(c.read(playbackProvider).slideIndex, 1);
      c.dispose();
    });

    test('P-02: next on last slide goes to next hymn slide 0', () async {
      final c = makeContainer();
      await setupOrder(c);

      final slides = c.read(playbackProvider).currentSub!.slides.length;
      for (var i = 0; i < slides - 1; i++) {
        c.read(playbackProvider.notifier).nextSlide();
      }
      expect(c.read(playbackProvider).slideIndex, slides - 1);

      c.read(playbackProvider.notifier).nextSlide();
      expect(c.read(playbackProvider).currentPath, hymnB);
      expect(c.read(playbackProvider).slideIndex, 0);
      c.dispose();
    });

    test('P-03: prev on first slide stays at 0', () async {
      final c = makeContainer();
      c.read(playbackProvider.notifier).loadSub(hymnA);

      c.read(playbackProvider.notifier).previousSlide();
      expect(c.read(playbackProvider).slideIndex, 0);
      c.dispose();
    });

    test('P-04: next on last hymn last slide stays', () async {
      final c = makeContainer();
      await setupOrder(c);

      c.read(orderProvider.notifier).setActiveItemIndex(1);
      c.read(playbackProvider.notifier).loadSub(hymnB);
      c.read(playbackProvider.notifier).goToSlide(1);
      c.read(playbackProvider.notifier).nextSlide();

      expect(c.read(playbackProvider).currentPath, hymnB);
      expect(c.read(playbackProvider).slideIndex, 1);
      c.dispose();
    });

    test('P-05: nextHymn on last hymn is no-op', () async {
      final c = makeContainer();
      await setupOrder(c);
      c.read(orderProvider.notifier).setActiveItemIndex(1);
      c.read(playbackProvider.notifier).loadSub(hymnB);

      c.read(playbackProvider.notifier).nextHymn();
      expect(c.read(playbackProvider).currentPath, hymnB);
      c.dispose();
    });

    test('P-06: previousHymn on first hymn keeps order index', () async {
      final c = makeContainer();
      await setupOrder(c);

      c.read(playbackProvider.notifier).previousHymn();
      expect(c.read(orderProvider).activeItemIndex, 0);
      expect(c.read(playbackProvider).currentPath, hymnA);
      c.dispose();
    });

    test('P-07: B toggle flips isBlack', () {
      final c = makeContainer();
      c.read(playbackProvider.notifier).loadSub(hymnA);

      expect(c.read(playbackProvider).isBlack, isFalse);
      c.read(playbackProvider.notifier).toggleBlack();
      expect(c.read(playbackProvider).isBlack, isTrue);
      c.read(playbackProvider.notifier).toggleBlack();
      expect(c.read(playbackProvider).isBlack, isFalse);
      c.dispose();
    });

    test('P-08: black and still are mutually exclusive', () {
      final c = makeContainer();
      c.read(playbackProvider.notifier).loadSub(hymnA);
      final n = c.read(playbackProvider.notifier);

      n.setBlack(true);
      expect(c.read(playbackProvider).isBlack, isTrue);
      expect(c.read(playbackProvider).isStill, isFalse);

      n.setStill(true);
      expect(c.read(playbackProvider).isStill, isTrue);
      expect(c.read(playbackProvider).isBlack, isFalse);

      n.setBlack(true);
      expect(c.read(playbackProvider).isBlack, isTrue);
      expect(c.read(playbackProvider).isStill, isFalse);

      n.resetOutputModes();
      expect(c.read(playbackProvider).isBlack, isFalse);
      expect(c.read(playbackProvider).isStill, isFalse);
      c.dispose();
    });

    test('P-09: still freezes sync payload slide index', () {
      final c = makeContainer();
      c.read(playbackProvider.notifier).loadSub(hymnA);
      final n = c.read(playbackProvider.notifier);

      n.setStill(true);
      n.nextSlide();

      final payload = n.buildSyncPayload();
      expect(payload.slideIndex, 0);
      expect(c.read(playbackProvider).slideIndex, 1);

      n.setStill(false);
      expect(n.buildSyncPayload().slideIndex, 1);
      c.dispose();
    });

    test('prepareForSlideEdit selects first slide when slideIndex is -1', () {
      final c = makeContainer();
      final sub = subIo.readFile(hymnA);
      c.read(playbackProvider.notifier).loadImportedSub(hymnA, sub);
      expect(c.read(playbackProvider).slideIndex, PlaybackNotifier.noSlideSelected);

      c.read(playbackProvider.notifier).prepareForSlideEdit();
      expect(c.read(playbackProvider).slideIndex, 0);
      expect(c.read(editorProvider).selectedElementId, isNotNull);
      c.dispose();
    });
  });
}
