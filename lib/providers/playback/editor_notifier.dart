part of 'playback.dart';

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
