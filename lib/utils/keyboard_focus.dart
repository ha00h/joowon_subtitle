import 'package:flutter/widgets.dart';

/// 검색창·다이얼로그 등 텍스트 입력 중인지 확인
bool isTextInputFocused() {
  final primary = FocusManager.instance.primaryFocus;
  final context = primary?.context;
  if (context == null) return false;

  if (context.widget is EditableText) return true;

  var editing = false;
  context.visitAncestorElements((element) {
    if (element.widget is EditableText) {
      editing = true;
      return false;
    }
    return true;
  });
  return editing;
}
