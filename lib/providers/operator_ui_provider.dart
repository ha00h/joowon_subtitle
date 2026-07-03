import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 슬라이드 그리드 열 수 (2=크게 ~ 5=작게)
class OperatorUiState {
  const OperatorUiState({this.gridColumns = 2});

  static const minGridColumns = 2;
  static const maxGridColumns = 5;

  final int gridColumns;

  OperatorUiState copyWith({int? gridColumns}) {
    return OperatorUiState(gridColumns: gridColumns ?? this.gridColumns);
  }
}

class OperatorUiNotifier extends Notifier<OperatorUiState> {
  @override
  OperatorUiState build() => const OperatorUiState();

  void setGridColumns(int columns) {
    final clamped = columns.clamp(
      OperatorUiState.minGridColumns,
      OperatorUiState.maxGridColumns,
    );
    state = state.copyWith(gridColumns: clamped);
  }
}

final operatorUiProvider =
    NotifierProvider<OperatorUiNotifier, OperatorUiState>(OperatorUiNotifier.new);
