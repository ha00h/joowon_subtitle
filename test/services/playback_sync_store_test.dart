import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/playback_sync_payload.dart';
import 'package:joowon_subtitle/models/sub_file.dart';
import 'package:joowon_subtitle/services/playback_sync_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('playback_sync_test');
    PlaybackSyncStore.testDirectoryOverride = tempDir;
    await PlaybackSyncStore.init();
  });

  tearDown(() {
    PlaybackSyncStore.testDirectoryOverride = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('write/readLatest round-trip with revision', () async {
    final sub = SubFile(
      title: '테스트',
      slides: const [],
    );

    await PlaybackSyncStore.write(
      PlaybackSyncPayload(sub: sub, slideIndex: 2, isBlank: false),
    );

    final first = PlaybackSyncStore.readLatest();
    expect(first, isNotNull);
    expect(first!.revision, 1);
    expect(first.payload.sub?.title, '테스트');
    expect(first.payload.slideIndex, 2);
    expect(first.payload.isBlank, isFalse);

    await PlaybackSyncStore.write(
      PlaybackSyncPayload(sub: sub, slideIndex: 3, isBlank: true),
    );

    final second = PlaybackSyncStore.readLatest();
    expect(second!.revision, 2);
    expect(second.payload.slideIndex, 3);
    expect(second.payload.isBlank, isTrue);
  });
}
