import 'package:flutter/material.dart';

import '../../widgets/editor/unified_editor_screen.dart';

/// 스타일 편집 화면 — 통합 에디터의 스타일 모드
class StyleScreen extends StatelessWidget {
  const StyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedEditorScreen(mode: UnifiedEditorMode.style);
  }
}
