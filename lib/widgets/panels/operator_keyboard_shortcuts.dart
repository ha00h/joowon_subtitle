import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/playback_provider.dart';
import '../../utils/keyboard_focus.dart';

const operatorKeyboardShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.arrowDown): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): PreviousSlideIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousSlideIntent(),
  SingleActivator(LogicalKeyboardKey.space): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.pageDown): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.pageUp): PreviousSlideIntent(),
  SingleActivator(LogicalKeyboardKey.keyB): ToggleBlankIntent(),
  SingleActivator(LogicalKeyboardKey.home): GoHomeIntent(),
  SingleActivator(LogicalKeyboardKey.enter): CommitDigitIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): CommitDigitIntent(),
  SingleActivator(LogicalKeyboardKey.digit1): DigitIntent('1'),
  SingleActivator(LogicalKeyboardKey.digit2): DigitIntent('2'),
  SingleActivator(LogicalKeyboardKey.digit3): DigitIntent('3'),
  SingleActivator(LogicalKeyboardKey.digit4): DigitIntent('4'),
  SingleActivator(LogicalKeyboardKey.digit5): DigitIntent('5'),
  SingleActivator(LogicalKeyboardKey.digit6): DigitIntent('6'),
  SingleActivator(LogicalKeyboardKey.digit7): DigitIntent('7'),
  SingleActivator(LogicalKeyboardKey.digit8): DigitIntent('8'),
  SingleActivator(LogicalKeyboardKey.digit9): DigitIntent('9'),
  SingleActivator(LogicalKeyboardKey.digit0): DigitIntent('0'),
  SingleActivator(LogicalKeyboardKey.delete): DeleteSlideIntent(),
};

Map<Type, Action<Intent>> buildOperatorKeyboardActions(WidgetRef ref) {
  final playback = ref.read(playbackProvider.notifier);
  return {
    NextSlideIntent: _OperatorAction<NextSlideIntent>(
      onInvoke: (_) => playback.nextSlide(),
    ),
    PreviousSlideIntent: _OperatorAction<PreviousSlideIntent>(
      onInvoke: (_) => playback.previousSlide(),
    ),
    ToggleBlankIntent: _OperatorAction<ToggleBlankIntent>(
      onInvoke: (_) => playback.toggleBlank(),
    ),
    GoHomeIntent: _OperatorAction<GoHomeIntent>(
      onInvoke: (_) => playback.goHome(),
    ),
    CommitDigitIntent: _OperatorAction<CommitDigitIntent>(
      onInvoke: (_) => playback.commitDigitBuffer(),
    ),
    DigitIntent: _OperatorAction<DigitIntent>(
      onInvoke: (intent) => playback.appendDigit(intent.digit),
    ),
    DeleteSlideIntent: _OperatorAction<DeleteSlideIntent>(
      onInvoke: (_) => playback.deleteSlide(),
    ),
  };
}

/// 텍스트 입력 포커스 시 비활성화 → 검색창 입력과 단축키 공존
class _OperatorAction<T extends Intent> extends Action<T> {
  _OperatorAction({required this.onInvoke});

  final void Function(T intent) onInvoke;

  @override
  bool isEnabled(T intent) => !isTextInputFocused();

  @override
  Object? invoke(T intent) {
    onInvoke(intent);
    return null;
  }
}

class NextSlideIntent extends Intent {
  const NextSlideIntent();
}

class PreviousSlideIntent extends Intent {
  const PreviousSlideIntent();
}

class ToggleBlankIntent extends Intent {
  const ToggleBlankIntent();
}

class GoHomeIntent extends Intent {
  const GoHomeIntent();
}

class CommitDigitIntent extends Intent {
  const CommitDigitIntent();
}

class DigitIntent extends Intent {
  const DigitIntent(this.digit);
  final String digit;
}

class DeleteSlideIntent extends Intent {
  const DeleteSlideIntent();
}
