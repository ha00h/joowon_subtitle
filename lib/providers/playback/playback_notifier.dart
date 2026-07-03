part of 'playback.dart';

class PlaybackNotifier extends Notifier<PlaybackState>
    with PlaybackSlideOpsMixin, PlaybackEditorOpsMixin {
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
    syncToOutput();
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
    syncToOutput();
  }

  void setBlankForReconnect() {
    state = state.copyWith(isBlack: true, isStill: false);
    _clearStillSnapshot();
    syncToOutput();
  }

  /// 송출 창 닫힘 시 black/still 초기화
  void resetOutputModes() {
    _clearStillSnapshot();
    state = state.copyWith(isBlack: false, isStill: false);
    syncToOutput();
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

  void syncToOutput() {
    PlaybackSyncService.push(buildSyncPayload());
  }

  /// 송출 창이 꺼져 있어도 저장소에 반영 (Off→On 시 즉시 표시용)
  void resyncToOutput() {
    syncToOutput();
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
      syncToOutput();
      return;
    }
    state = state.copyWith(isBlack: true, isStill: false);
    _clearStillSnapshot();
    syncToOutput();
  }

  void toggleBlack() {
    setBlack(!state.isBlack);
  }

  void setStill(bool on) {
    if (!on) {
      state = state.copyWith(isStill: false);
      _clearStillSnapshot();
      syncToOutput();
      return;
    }
    _captureStillSnapshot();
    state = state.copyWith(isStill: true, isBlack: false);
    syncToOutput();
  }

  void toggleStill() {
    setStill(!state.isStill);
  }

  void pushUndo() {
    final sub = state.currentSub;
    if (sub != null) {
      _undoStack.push(sub.copyWith());
    }
    ref.read(editorProvider.notifier).syncUndoFlags(
          canUndo: _undoStack.canUndo,
          canRedo: _undoStack.canRedo,
        );
  }

  void applySub(SubFile sub, {bool save = true, bool syncOutput = false}) {
    state = state.copyWith(currentSub: sub);
    if (save && state.currentPath != null) {
      _subIo.writeFile(state.currentPath!, sub);
    }
    if (syncOutput) syncToOutput();
  }

  void updateSub(SubFile sub, {bool recordUndo = true}) {
    if (recordUndo) pushUndo();
    applySub(sub, syncOutput: true);
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
      applySub(prev, syncOutput: true);
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
      applySub(next, syncOutput: true);
      ref.read(editorProvider.notifier).syncUndoFlags(
            canUndo: _undoStack.canUndo,
            canRedo: _undoStack.canRedo,
          );
    }
  }

  SubFile? get currentSub => state.currentSub;

  List<SlideElement> currentElements() {
    final sub = currentSub;
    if (sub == null || sub.slides.isEmpty || state.slideIndex < 0) return [];
    final idx = state.slideIndex.clamp(0, sub.slides.length - 1);
    return sub.slides[idx].elements;
  }

  SubFile? buildUpdatedSub(List<SlideElement> elements) {
    final sub = currentSub;
    if (sub == null) return null;
    final idx = state.slideIndex;
    if (idx < 0 || idx >= sub.slides.length) return null;

    final slides = [...sub.slides];
    slides[idx] = Slide(elements: elements);
    return sub.copyWith(slides: slides);
  }

  void updateCurrentSlideElements(List<SlideElement> elements) {
    final updated = buildUpdatedSub(elements);
    if (updated != null) updateSub(updated);
  }

  void selectElement(String? id) {
    ref.read(editorProvider.notifier).selectElement(id);
  }

  void goToSlide(int index) {
    final sub = currentSub;
    if (sub == null || sub.slides.isEmpty) return;
    final clamped = index.clamp(0, sub.slides.length - 1);
    if (clamped != state.slideIndex) {
      state = state.copyWith(slideIndex: clamped);
      selectElement(null);
    }
    syncToOutput();
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
      syncToOutput();
      return;
    }

    advanceToNextOrderItem();
  }

  void previousSlide() {
    if (state.slideIndex > 0) {
      state = state.copyWith(
        slideIndex: state.slideIndex - 1,
        clearDigitBuffer: true,
      );
      selectElement(null);
      syncToOutput();
      return;
    }

    retreatToPreviousOrderItem();
  }

  void nextHymn() {
    advanceToNextOrderItem(forceNextHymn: true);
  }

  void previousHymn() {
    retreatToPreviousOrderItem(forcePreviousHymn: true);
  }

  void goHome() {
    state = state.copyWith(slideIndex: 0, clearDigitBuffer: true);
    selectElement(null);
    syncToOutput();
  }

  void advanceToNextOrderItem({bool forceNextHymn = false}) {
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

  void retreatToPreviousOrderItem({bool forcePreviousHymn = false}) {
    final orderState = ref.read(orderProvider);
    final order = orderState.activeOrder;
    if (order == null || order.items.isEmpty) return;

    var itemIndex = orderState.activeItemIndex;
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
    syncToOutput();
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
