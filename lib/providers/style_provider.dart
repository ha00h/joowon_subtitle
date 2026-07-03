import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../models/style_file.dart';
import '../services/style_store.dart';
import 'settings_provider.dart';

class StyleState {
  StyleState({
    StyleFile? style,
    this.activePath,
    this.catalog = const [],
    this.initialized = false,
  }) : style = style ?? StyleFile.defaultStyle;

  final StyleFile style;
  final String? activePath;
  final List<StyleEntry> catalog;
  final bool initialized;

  StyleState copyWith({
    StyleFile? style,
    String? activePath,
    List<StyleEntry>? catalog,
    bool? initialized,
    bool clearActivePath = false,
  }) {
    return StyleState(
      style: style ?? this.style,
      activePath: clearActivePath ? null : (activePath ?? this.activePath),
      catalog: catalog ?? this.catalog,
      initialized: initialized ?? this.initialized,
    );
  }
}

final styleStoreProvider = Provider<StyleStore>((ref) => StyleStore());

class StyleNotifier extends Notifier<StyleState> {
  late StyleStore _store;

  @override
  StyleState build() {
    _store = ref.read(styleStoreProvider);
    return StyleState();
  }

  Future<void> initialize() async {
    if (state.initialized) return;

    await _store.ensureDefaultStyle();
    var catalog = await _store.listStyles();
    var activePath = ref.read(settingsProvider).stylePath;

    activePath = await _migrateExternalStyleIfNeeded(activePath, catalog);
    catalog = await _store.listStyles();

    StyleEntry? activeEntry;
    if (activePath != null) {
      activeEntry = _store.findByPath(catalog, activePath);
    }
    if (activeEntry == null) {
      for (final entry in catalog) {
        if (entry.path.endsWith(StyleStore.defaultFileName)) {
          activeEntry = entry;
          break;
        }
      }
    }
    activeEntry ??= catalog.isNotEmpty ? catalog.first : null;

    if (activeEntry != null) {
      activePath = activeEntry.path;
      await ref.read(settingsProvider.notifier).setStylePath(activePath);
    }

    state = StyleState(
      style: activeEntry?.style ?? StyleFile.defaultStyle,
      activePath: activePath,
      catalog: catalog,
      initialized: true,
    );
  }

  Future<String?> _migrateExternalStyleIfNeeded(
    String? activePath,
    List<StyleEntry> catalog,
  ) async {
    if (activePath == null || activePath.isEmpty) return null;

    final stylesDir = await _store.directoryPath();
    if (p.isWithin(stylesDir, activePath) || activePath.startsWith(stylesDir)) {
      return activePath;
    }

    if (!File(activePath).existsSync()) return null;

    final imported = await _store.importExternalStyle(activePath);
    await ref.read(settingsProvider.notifier).setStylePath(imported);
    return imported;
  }

  Future<void> refreshCatalog() async {
    final catalog = await _store.listStyles();
    state = state.copyWith(catalog: catalog);
  }

  Future<void> selectStyle(StyleEntry entry) async {
    await ref.read(settingsProvider.notifier).setStylePath(entry.path);
    state = state.copyWith(style: entry.style, activePath: entry.path);
  }

  Future<StyleEntry> createStyle({String name = '새 스타일'}) async {
    final style = StyleFile.defaultStyle.copyWith(name: name);
    final path = await _store.createStyle(style);
    await refreshCatalog();
    final entry = _store.findByPath(state.catalog, path);
    if (entry == null) {
      throw StateError('생성한 스타일을 찾을 수 없습니다');
    }
    return entry;
  }

  Future<void> saveStyle(String path, StyleFile style) async {
    await _store.saveStyle(path, style);
    await refreshCatalog();

    if (state.activePath == path) {
      state = state.copyWith(style: style);
    }
  }

  Future<void> deleteStyle(StyleEntry entry) async {
    if (state.catalog.length <= 1) {
      throw StateError('마지막 스타일은 삭제할 수 없습니다');
    }

    await _store.deleteStyle(entry.path);
    await refreshCatalog();

    if (state.activePath == entry.path) {
      final next = state.catalog.first;
      await selectStyle(next);
    }
  }

  void applyStyleDraft(StyleFile style) {
    state = state.copyWith(style: style);
  }
}

final styleProvider = NotifierProvider<StyleNotifier, StyleState>(
  StyleNotifier.new,
);

/// 렌더링·동기화용 활성 StyleFile
final activeStyleFileProvider = Provider<StyleFile>(
  (ref) => ref.watch(styleProvider).style,
);

/// 하위 호환 alias
final activeStyleProvider = activeStyleFileProvider;
