part of 'playback.dart';

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
