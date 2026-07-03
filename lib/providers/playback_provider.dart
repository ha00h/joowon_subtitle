import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_fonts.dart';
import '../models/playback_sync_payload.dart';
import '../models/slide_elements.dart';
import '../models/style_file.dart';
import '../models/sub_file.dart';
import '../services/playback_sync_service.dart';
import '../services/sub_io.dart';
import '../services/undo_stack.dart';
import 'order_provider.dart';
import 'settings_provider.dart';
import 'style_provider.dart';

final subIoProvider = Provider<SubIo>((ref) => SubIo());

const _uuid = Uuid();

enum SlidePanelLayout { singleSong, orderSequence }

class PlaybackState {
  const PlaybackState({
    this.currentSub,
    this.currentPath,
    this.slideIndex = 0,
    this.isBlack = false,
    this.isStill = false,
    this.digitBuffer = '',
    this.panelLayout = SlidePanelLayout.singleSong,
  });

  final SubFile? currentSub;
  final String? currentPath;
  final int slideIndex;
  /// 송출 화면을 검정으로 덮음 (B키)
  final bool isBlack;
  /// 송출 화면 고정 — 조작해도 송출 내용 유지
  final bool isStill;
  final String digitBuffer;
  final SlidePanelLayout panelLayout;

  PlaybackState copyWith({
    SubFile? currentSub,
    String? currentPath,
    int? slideIndex,
    bool? isBlack,
    bool? isStill,
    String? digitBuffer,
    SlidePanelLayout? panelLayout,
    bool clearDigitBuffer = false,
  }) {
    return PlaybackState(
      currentSub: currentSub ?? this.currentSub,
      currentPath: currentPath ?? this.currentPath,
      slideIndex: slideIndex ?? this.slideIndex,
      isBlack: isBlack ?? this.isBlack,
      isStill: isStill ?? this.isStill,
      digitBuffer: clearDigitBuffer ? '' : (digitBuffer ?? this.digitBuffer),
      panelLayout: panelLayout ?? this.panelLayout,
    );
  }
}

class EditorState {
  const EditorState({
    this.selectedElementId,
    this.canUndo = false,
    this.canRedo = false,
  });

  final String? selectedElementId;
  final bool canUndo;
  final bool canRedo;

  EditorState copyWith({
    String? selectedElementId,
    bool clearSelection = false,
    bool? canUndo,
    bool? canRedo,
  }) {
    return EditorState(
      selectedElementId:
          clearSelection ? null : (selectedElementId ?? this.selectedElementId),
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

class PlaybackNotifier extends Notifier<PlaybackState> {
  late SubIo _subIo;
  final _undoStack = UndoStack<SubFile>();
  PlaybackSyncPayload? _stillSnapshot;

  @override
  PlaybackState build() {
    _subIo = ref.read(subIoProvider);
    return const PlaybackState();
  }

  static const int noSlideSelected = -1;

  void loadSub(
    String path, {
    SlidePanelLayout layout = SlidePanelLayout.singleSong,
    int slideIndex = 0,
  }) {
    final sub = _subIo.readFile(path);
    _undoStack.clear();
    state = PlaybackState(
      currentSub: sub,
      currentPath: path,
      slideIndex: slideIndex,
      isBlack: state.isBlack,
      isStill: state.isStill,
      panelLayout: layout,
    );
    ref.read(editorProvider.notifier).onSubLoaded();
    _syncToOutput();
  }

  /// Import 완료 후 — 슬라이드 미선택 상태로 로드
  void loadImportedSub(String path, SubFile sub) {
    _undoStack.clear();
    state = PlaybackState(
      currentSub: sub,
      currentPath: path,
      slideIndex: noSlideSelected,
      isBlack: state.isBlack,
      isStill: state.isStill,
      panelLayout: SlidePanelLayout.singleSong,
    );
    ref.read(editorProvider.notifier).onSubLoaded();
    _syncToOutput();
  }

  void setBlankForReconnect() {
    state = state.copyWith(isBlack: true, isStill: false);
    _clearStillSnapshot();
    _syncToOutput();
  }

  /// 송출 창 닫힘 시 black/still 초기화
  void resetOutputModes() {
    _clearStillSnapshot();
    state = state.copyWith(isBlack: false, isStill: false);
    _syncToOutput();
  }

  PlaybackSyncPayload buildSyncPayload() {
    final style = ref.read(activeStyleFileProvider);
    final settings = ref.read(settingsProvider);

    if (state.isStill && _stillSnapshot != null) {
      return _stillSnapshot!.copyWith(
        style: style,
        outputBackground: settings.outputBackground.name,
      );
    }

    return PlaybackSyncPayload(
      sub: state.currentSub,
      slideIndex: state.slideIndex,
      isBlank: state.isBlack,
      style: style,
      outputBackground: settings.outputBackground.name,
    );
  }

  void _syncToOutput() {
    PlaybackSyncService.push(buildSyncPayload());
  }

  /// 송출 창이 꺼져 있어도 저장소에 반영 (Off→On 시 즉시 표시용)
  void resyncToOutput() {
    _syncToOutput();
  }

  void _captureStillSnapshot() {
    final style = ref.read(activeStyleFileProvider);
    final settings = ref.read(settingsProvider);
    _stillSnapshot = PlaybackSyncPayload(
      sub: state.currentSub,
      slideIndex: state.slideIndex,
      isBlank: false,
      style: style,
      outputBackground: settings.outputBackground.name,
    );
  }

  void _clearStillSnapshot() {
    _stillSnapshot = null;
  }

  void setBlack(bool on) {
    if (!on) {
      state = state.copyWith(isBlack: false);
      _syncToOutput();
      return;
    }
    state = state.copyWith(isBlack: true, isStill: false);
    _clearStillSnapshot();
    _syncToOutput();
  }

  void toggleBlack() {
    setBlack(!state.isBlack);
  }

  void setStill(bool on) {
    if (!on) {
      state = state.copyWith(isStill: false);
      _clearStillSnapshot();
      _syncToOutput();
      return;
    }
    _captureStillSnapshot();
    state = state.copyWith(isStill: true, isBlack: false);
    _syncToOutput();
  }

  void toggleStill() {
    setStill(!state.isStill);
  }

  void _pushUndo() {
    final sub = state.currentSub;
    if (sub != null) {
      _undoStack.push(sub.copyWith());
    }
    ref.read(editorProvider.notifier).syncUndoFlags(
          canUndo: _undoStack.canUndo,
          canRedo: _undoStack.canRedo,
        );
  }

  void _applySub(SubFile sub, {bool save = true, bool syncOutput = false}) {
    state = state.copyWith(currentSub: sub);
    if (save && state.currentPath != null) {
      _subIo.writeFile(state.currentPath!, sub);
    }
    if (syncOutput) _syncToOutput();
  }

  void updateSub(SubFile sub, {bool recordUndo = true}) {
    if (recordUndo) _pushUndo();
    _applySub(sub, syncOutput: true);
    ref.read(editorProvider.notifier).syncUndoFlags(
          canUndo: _undoStack.canUndo,
          canRedo: _undoStack.canRedo,
        );
  }

  void undo() {
    final current = state.currentSub;
    if (current == null) return;
    final prev = _undoStack.undo(current);
    if (prev != null) {
      _applySub(prev, syncOutput: true);
      ref.read(editorProvider.notifier).syncUndoFlags(
            canUndo: _undoStack.canUndo,
            canRedo: _undoStack.canRedo,
          );
    }
  }

  void redo() {
    final current = state.currentSub;
    if (current == null) return;
    final next = _undoStack.redo(current);
    if (next != null) {
      _applySub(next, syncOutput: true);
      ref.read(editorProvider.notifier).syncUndoFlags(
            canUndo: _undoStack.canUndo,
            canRedo: _undoStack.canRedo,
          );
    }
  }

  SubFile? get _sub => state.currentSub;

  List<SlideElement> _currentElements() {
    final sub = _sub;
    if (sub == null || sub.slides.isEmpty || state.slideIndex < 0) return [];
    final idx = state.slideIndex.clamp(0, sub.slides.length - 1);
    return sub.slides[idx].elements;
  }

  SubFile? _buildUpdatedSub(List<SlideElement> elements) {
    final sub = _sub;
    if (sub == null) return null;
    final idx = state.slideIndex;
    if (idx < 0 || idx >= sub.slides.length) return null;

    final slides = [...sub.slides];
    slides[idx] = Slide(elements: elements);
    return sub.copyWith(slides: slides);
  }

  void _updateCurrentSlideElements(List<SlideElement> elements) {
    final updated = _buildUpdatedSub(elements);
    if (updated != null) updateSub(updated);
  }

  void selectElement(String? id) {
    ref.read(editorProvider.notifier).selectElement(id);
  }

  void updateElement(SlideElement updated) {
    final elements = _currentElements()
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    _updateCurrentSlideElements(elements);
  }

  void moveElement(String id, double x, double y, {bool recordUndo = true}) {
    if (recordUndo) _pushUndo();
    final elements = _currentElements().map((e) {
      if (e.id != id) return e;
      return e.copyWith(x: x.clamp(0, 100), y: y.clamp(0, 100));
    }).toList();
    final updated = _buildUpdatedSub(elements);
    if (updated != null) {
      _applySub(updated, syncOutput: true);
    }
  }

  void updateTextLines(String id, List<String> lines) {
    final elements = _currentElements().map((e) {
      if (e.id != id) return e;
      return e.copyWith(lines: lines);
    }).toList();
    _updateCurrentSlideElements(elements);
  }

  void applyStyleToSlide(StyleFile style, {bool allSlides = false}) {
    final sub = _sub;
    if (sub == null) return;

    final region = style.primaryBodyRegion;
    final text = style.text;

    List<SlideElement> styledElements(List<SlideElement> elements) {
      return elements
          .map(
            (e) => applyStyleConfigToTextElement(
              e,
              text,
              x: region.x,
              y: region.y,
            ),
          )
          .toList();
    }

    if (allSlides) {
      final slides = sub.slides
          .map((s) => Slide(elements: styledElements(s.elements)))
          .toList();
      updateSub(sub.copyWith(slides: slides));
      return;
    }

    final idx = state.slideIndex;
    if (idx < 0 || idx >= sub.slides.length) return;
    final slides = [...sub.slides];
    slides[idx] = Slide(elements: styledElements(slides[idx].elements));
    updateSub(sub.copyWith(slides: slides));
  }

  void addTextElement() {
    final style = ref.read(activeStyleFileProvider);
    final region = style.primaryBodyRegion;
    final el = SlideElement(
      id: _uuid.v4(),
      type: SlideElementType.text,
      x: region.x,
      y: region.y,
      zIndex: _nextZIndex(),
      lines: const ['새 가사'],
      anchor: 'topLeft',
    );
    _updateCurrentSlideElements([..._currentElements(), el]);
    selectElement(el.id);
  }

  void addShape(ShapeType shapeType) {
    final el = SlideElement(
      id: _uuid.v4(),
      type: SlideElementType.shape,
      x: 50,
      y: 50,
      width: 30,
      height: 20,
      zIndex: _nextZIndex(),
      shapeType: shapeType,
      strokeWidth: 3,
    );
    _updateCurrentSlideElements([..._currentElements(), el]);
    selectElement(el.id);
  }

  Future<void> addImageFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    final bytes = await File(path).readAsBytes();
    final base64 = base64Encode(bytes);

    final el = SlideElement(
      id: _uuid.v4(),
      type: SlideElementType.image,
      x: 50,
      y: 50,
      width: 25,
      height: 25,
      zIndex: _nextZIndex(),
      data: base64,
      mimeType: 'image/png',
    );
    _updateCurrentSlideElements([..._currentElements(), el]);
    selectElement(el.id);
  }

  void deleteSelectedElement() {
    final id = ref.read(editorProvider).selectedElementId;
    if (id == null) return;
    _updateCurrentSlideElements(
      _currentElements().where((e) => e.id != id).toList(),
    );
    selectElement(null);
  }

  int _nextZIndex() {
    final els = _currentElements();
    if (els.isEmpty) return 0;
    return els.map((e) => e.zIndex).reduce((a, b) => a > b ? a : b) + 1;
  }

  void addSlide() {
    final sub = _sub;
    if (sub == null) return;

    final style = ref.read(activeStyleFileProvider);
    final region = style.primaryBodyRegion;

    final slide = Slide(
      elements: [
        SlideElement(
          id: _uuid.v4(),
          type: SlideElementType.text,
          x: region.x,
          y: region.y,
          zIndex: 0,
          lines: const [''],
          anchor: 'topLeft',
        ),
      ],
    );
    final slides = [...sub.slides, slide];
    updateSub(sub.copyWith(slides: slides));
    state = state.copyWith(slideIndex: slides.length - 1);
    _syncToOutput();
  }

  void deleteSlide() {
    deleteSlideAt(state.slideIndex);
  }

  void deleteSlideAt(int index) {
    final sub = _sub;
    if (sub == null || sub.slides.length <= 1) return;
    if (index < 0 || index >= sub.slides.length) return;

    final slides = [...sub.slides]..removeAt(index);
    updateSub(sub.copyWith(slides: slides));
    final nextIndex = index >= slides.length ? slides.length - 1 : index;
    state = state.copyWith(slideIndex: nextIndex);
    selectElement(null);
    _syncToOutput();
  }

  void duplicateSlideAfter(int index) {
    final sub = _sub;
    if (sub == null || index < 0 || index >= sub.slides.length) return;

    final source = sub.slides[index];
    final copy = Slide(
      tag: source.tag,
      elements: source.elements
          .map(
            (e) => e.copyWith(id: _uuid.v4()),
          )
          .toList(),
    );
    final slides = [...sub.slides];
    slides.insert(index + 1, copy);
    updateSub(sub.copyWith(slides: slides));
    state = state.copyWith(slideIndex: index + 1);
    _syncToOutput();
  }

  void duplicateSlide() {
    final idx = state.slideIndex;
    if (idx < 0) return;
    duplicateSlideAfter(idx);
  }

  void setSlideTag(int index, String? tag) {
    final sub = _sub;
    if (sub == null || index < 0 || index >= sub.slides.length) return;

    final slides = [...sub.slides];
    slides[index] = slides[index].copyWith(
      tag: tag,
      clearTag: tag == null,
    );
    updateSub(sub.copyWith(slides: slides));
  }

  void updateSlideTextAt(int index, List<String> lines) {
    final sub = _sub;
    if (sub == null || index < 0 || index >= sub.slides.length) return;

    final slide = sub.slides[index];
    var textUpdated = false;
    final elements = slide.elements.map((e) {
      if (!textUpdated && e.type == SlideElementType.text) {
        textUpdated = true;
        return e.copyWith(lines: lines);
      }
      return e;
    }).toList();

    if (!textUpdated) {
      final style = ref.read(activeStyleFileProvider);
      final region = style.primaryBodyRegion;
      elements.add(
        SlideElement(
          id: _uuid.v4(),
          type: SlideElementType.text,
          x: region.x,
          y: region.y,
          zIndex: 0,
          lines: lines,
          anchor: 'topLeft',
        ),
      );
    }

    final slides = [...sub.slides];
    slides[index] = Slide(elements: elements, tag: slide.tag);
    updateSub(sub.copyWith(slides: slides));
  }

  void goToSlide(int index) {
    final sub = _sub;
    if (sub == null || sub.slides.isEmpty) return;
    final clamped = index.clamp(0, sub.slides.length - 1);
    if (clamped != state.slideIndex) {
      state = state.copyWith(slideIndex: clamped);
      selectElement(null);
    }
    _syncToOutput();
  }

  /// 편집 창 진입 전 — 슬라이드 미선택(-1) 상태면 첫 슬라이드로 전환
  void prepareForSlideEdit() {
    final sub = _sub;
    if (sub == null || sub.slides.isEmpty) return;

    if (state.slideIndex < 0) {
      state = state.copyWith(slideIndex: 0);
      _syncToOutput();
    }

    final idx = state.slideIndex.clamp(0, sub.slides.length - 1);
    SlideElement? firstText;
    for (final el in sub.slides[idx].elements) {
      if (el.type == SlideElementType.text) {
        firstText = el;
        break;
      }
    }
    selectElement(firstText?.id);
  }

  void appendDigit(String digit) {
    final buf = state.digitBuffer + digit;
    if (buf.length > 3) return;
    state = state.copyWith(digitBuffer: buf);
  }

  void commitDigitBuffer() {
    final buf = state.digitBuffer;
    if (buf.isEmpty) return;
    final n = int.tryParse(buf);
    if (n != null && n >= 1) {
      goToSlide(n - 1);
    }
    state = state.copyWith(clearDigitBuffer: true);
  }

  void nextSlide() {
    final sub = state.currentSub;
    if (sub == null || sub.slides.isEmpty) return;

    if (state.slideIndex < 0) {
      goToSlide(0);
      return;
    }

    if (state.slideIndex < sub.slides.length - 1) {
      state = state.copyWith(
        slideIndex: state.slideIndex + 1,
        clearDigitBuffer: true,
      );
      selectElement(null);
      _syncToOutput();
      return;
    }

    _advanceToNextOrderItem();
  }

  void previousSlide() {
    if (state.slideIndex > 0) {
      state = state.copyWith(
        slideIndex: state.slideIndex - 1,
        clearDigitBuffer: true,
      );
      selectElement(null);
      _syncToOutput();
      return;
    }

    _retreatToPreviousOrderItem();
  }

  void nextHymn() {
    _advanceToNextOrderItem(forceNextHymn: true);
  }

  void previousHymn() {
    _retreatToPreviousOrderItem(forcePreviousHymn: true);
  }

  void goHome() {
    state = state.copyWith(slideIndex: 0, clearDigitBuffer: true);
    selectElement(null);
    _syncToOutput();
  }

  void _advanceToNextOrderItem({bool forceNextHymn = false}) {
    final orderState = ref.read(orderProvider);
    final order = orderState.activeOrder;
    if (order == null || order.items.isEmpty) return;

    var itemIndex = orderState.activeItemIndex;
    if (!forceNextHymn && itemIndex >= order.items.length - 1) return;

    itemIndex = forceNextHymn ? itemIndex + 1 : itemIndex + 1;
    if (itemIndex >= order.items.length) return;

    ref.read(orderProvider.notifier).setActiveItemIndex(itemIndex);
    loadSub(
      order.items[itemIndex].filePath,
      layout: SlidePanelLayout.orderSequence,
    );
  }

  void _retreatToPreviousOrderItem({bool forcePreviousHymn = false}) {
    final orderState = ref.read(orderProvider);
    final order = orderState.activeOrder;
    if (order == null || order.items.isEmpty) return;

    var itemIndex = orderState.activeItemIndex;
    if (!forcePreviousHymn) {
      // 이미 첫 슬라이드 — 이전 곡 마지막 슬라이드로
    }
    itemIndex = forcePreviousHymn ? itemIndex - 1 : itemIndex - 1;
    if (itemIndex < 0) return;

    ref.read(orderProvider.notifier).setActiveItemIndex(itemIndex);
    final path = order.items[itemIndex].filePath;
    final sub = _subIo.readFile(path);
    _undoStack.clear();
    state = PlaybackState(
      currentSub: sub,
      currentPath: path,
      slideIndex: sub.slides.isEmpty ? 0 : sub.slides.length - 1,
      isBlack: state.isBlack,
      isStill: state.isStill,
      panelLayout: SlidePanelLayout.orderSequence,
    );
    ref.read(editorProvider.notifier).onSubLoaded();
    _syncToOutput();
  }

  void toggleBlank() => toggleBlack();

  void loadOrderItem(int itemIndex, {int slideIndex = 0}) {
    final order = ref.read(orderProvider).activeOrder;
    if (order == null || itemIndex < 0 || itemIndex >= order.items.length) {
      return;
    }
    ref.read(orderProvider.notifier).setActiveItemIndex(itemIndex);
    loadSub(
      order.items[itemIndex].filePath,
      layout: SlidePanelLayout.orderSequence,
      slideIndex: slideIndex,
    );
  }
}

class EditorNotifier extends Notifier<EditorState> {
  @override
  EditorState build() => const EditorState();

  void onSubLoaded() {
    state = const EditorState();
  }

  void selectElement(String? id) {
    state = state.copyWith(
      selectedElementId: id,
      clearSelection: id == null,
    );
  }

  void syncUndoFlags({required bool canUndo, required bool canRedo}) {
    state = state.copyWith(canUndo: canUndo, canRedo: canRedo);
  }
}

final playbackProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);

final editorProvider =
    NotifierProvider<EditorNotifier, EditorState>(EditorNotifier.new);

/// 편집용 기본 텍스트 스타일 override 헬퍼
SlideElement applyFontOverride(SlideElement el, String fontFamily) {
  return el.copyWith(fontFamily: fontFamily);
}

SlideElement applyFontSizeOverride(SlideElement el, double size) {
  return el.copyWith(fontSize: size);
}

SlideElement applyFontWeightOverride(SlideElement el, int weight) {
  return el.copyWith(fontWeight: weight);
}

SlideElement applyColorOverride(SlideElement el, String color) {
  return el.copyWith(color: color);
}

/// 요소에 지정된 텍스트 스타일 override를 제거하고 스타일 기본값을 따르게 함
SlideElement clearTextStyleOverrides(SlideElement el) {
  return SlideElement(
    id: el.id,
    type: el.type,
    x: el.x,
    y: el.y,
    zIndex: el.zIndex,
    lines: el.lines,
    anchor: el.anchor,
  );
}

SlideElement applyStyleConfigToTextElement(
  SlideElement element,
  TextStyleConfig text, {
  required double x,
  required double y,
}) {
  if (element.type != SlideElementType.text) return element;
  return element.copyWith(
    fontFamily: text.fontFamily,
    fontSize: text.fontSize,
    fontWeight: text.fontWeight,
    color: text.color,
    textStrokeWidth: text.strokeWidth,
    textStrokeColor: text.strokeColor,
    shadowEnabled: text.shadow.enabled,
    shadowOffsetX: text.shadow.offsetX,
    shadowOffsetY: text.shadow.offsetY,
    shadowBlur: text.shadow.blur,
    shadowColor: text.shadow.color,
    textShadow: text.shadow.toCssShadow(),
    textAlign: text.textAlign,
    x: x,
    y: y,
    anchor: 'topLeft',
  );
}

String defaultFontFamily() => AppFonts.defaultFamily;
