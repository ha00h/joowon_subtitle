/// 간단한 Undo/Redo 스택 (SubFile 스냅샷 등)
class UndoStack<T> {
  UndoStack({this.maxDepth = 50});

  final int maxDepth;
  final _undo = <T>[];
  final _redo = <T>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(T state) {
    _undo.add(state);
    if (_undo.length > maxDepth) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  T? undo(T current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  T? redo(T current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
