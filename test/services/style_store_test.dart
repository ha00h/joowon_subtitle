import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/style_file.dart';
import 'package:joowon_subtitle/services/style_store.dart';

void main() {
  group('StyleStore', () {
    late Directory tempDir;
    late StyleStore store;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('style_store_');
      StyleStore.testDirectoryOverride = tempDir.path;
      store = StyleStore();
    });

    tearDown(() {
      StyleStore.testDirectoryOverride = null;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ensureDefaultStyle creates 기본.style', () async {
      await store.ensureDefaultStyle();
      final entries = await store.listStyles();
      expect(entries.length, 1);
      expect(entries.first.name, '기본');
      expect(entries.first.path, endsWith(StyleStore.defaultFileName));
    });

    test('createStyle adds a new file', () async {
      await store.ensureDefaultStyle();
      final custom = StyleFile.defaultStyle.copyWith(name: '주일예배');
      final path = await store.createStyle(custom);
      final entries = await store.listStyles();
      expect(entries.length, 2);
      expect(store.findByPath(entries, path)?.name, '주일예배');
    });

    test('findByPath returns matching entry', () async {
      await store.ensureDefaultStyle();
      final entries = await store.listStyles();
      expect(store.findByPath(entries, entries.first.path)?.name, '기본');
      expect(store.findByPath(entries, '/missing.style'), isNull);
    });

    test('deleteStyle removes file', () async {
      await store.ensureDefaultStyle();
      final path = await store.createStyle(
        StyleFile.defaultStyle.copyWith(name: '삭제용'),
      );
      await store.deleteStyle(path);
      final entries = await store.listStyles();
      expect(entries.length, 1);
      expect(entries.first.name, '기본');
    });
  });
}