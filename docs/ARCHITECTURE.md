# Joowon Subtitle — 기술 아키텍처

> 기준: [MVP.md](./MVP.md) v0.6  
> 플랫폼: Flutter 3.x Desktop

---

## 1. 개요

```
┌─────────────────────────────────────────────────────────┐
│                    Joowon Subtitle App                   │
├──────────────────────┬──────────────────────────────────┤
│   Operator Window    │      Output Window (Phase B)      │
│   (조작 + 편집)       │      (송출 전용, FHD 16:9)         │
│                      │                                   │
│  ┌────────┬─────────┐│  CanvasRenderer (read-only)      │
│  │ Search │ Canvas  ││  black / transparent bg          │
│  │ Order  │ Style   ││                                   │
│  └────────┴─────────┘│                                   │
└──────────────────────┴──────────────────────────────────┘
         │                        ▲
         │    PlaybackState       │ sync
         └────────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
 FileService    OrderRepository   SettingsStore
 (.sub/.style)  (Hive)            (Hive/prefs)
    │
    ▼
 Workspace Folder (dart:io)
```

**Phase A:** Output = Operator 내 `OutputRoute` 또는 split view  
**Phase B:** Output = `desktop_multi_window` 별도 윈도우

---

## 2. 레이어 구조

```
lib/
├── main.dart                 # 진입, 윈도우 초기화
├── app.dart                  # MaterialApp, 테마, 라우팅
│
├── models/                   # 순수 데이터 (JSON ↔ Dart)
│   ├── sub_file.dart
│   ├── style_file.dart
│   ├── slide.dart
│   ├── elements/             # text, image, shape
│   ├── playback_state.dart
│   └── service_order.dart
│
├── services/
│   ├── txt_parser.dart       # .txt → slides
│   ├── sub_io.dart           # .sub read/write, auto-save
│   ├── style_io.dart
│   ├── workspace_scanner.dart # 재귀 .sub/.style 검색
│   ├── style_resolver.dart   # override merge
│   ├── monitor_service.dart  # screen_retriever (Windows)
│   ├── output_window_service.dart
│   └── undo_stack.dart
│
├── repositories/
│   ├── settings_repository.dart
│   └── order_repository.dart  # Hive
│
├── providers/                # Riverpod
│   ├── settings_provider.dart
│   ├── workspace_provider.dart
│   ├── playback_provider.dart
│   ├── editor_provider.dart
│   └── order_provider.dart
│
├── windows/
│   ├── operator/
│   │   ├── operator_screen.dart
│   │   ├── panels/           # search, order, style, status
│   │   └── settings_screen.dart
│   └── output/
│       └── output_screen.dart
│
└── widgets/
    ├── canvas/
    │   ├── subtitle_canvas.dart   # 16:9 FHD
    │   ├── canvas_renderer.dart   # 요소 → Widget
    │   └── canvas_editor.dart     # 선택·드래그·편집
    ├── elements/
    │   ├── text_element_widget.dart
    │   ├── image_element_widget.dart
    │   └── shape_element_widget.dart
    └── common/
        └── aspect_ratio_fhd.dart  # 1920:1080
```

---

## 3. 상태 관리

### 3.1 PlaybackState (송출 핵심)

```dart
class PlaybackState {
  final String? hymnFilePath;
  final String? hymnTitle;
  final int slideIndex;       // 0-based
  final int orderIndex;       // 예배 순서 내 곡 index
  final bool isBlank;         // B키
  final bool outputConnected;
}
```

- **Single source of truth:** `playbackProvider` (Riverpod)
- Phase A: 동일 isolate 내 `OutputRoute` 구독
- Phase B: `MethodChannel` / `desktop_multi_window` 로 Output에 push

### 3.2 EditorState (편집)

```dart
class EditorState {
  final SubFile? currentSub;
  final String? selectedElementId;
  final StyleFile? activeStyle;
  final bool isDirty;
}
```

- 편집 변경 → `UndoStack` push → `sub_io.autoSave()`
- `style_resolver.resolve(element, activeStyle, appDefaults)` → 렌더용 `ResolvedElement`

### 3.3 스타일 merge

```
ResolvedTextStyle resolve(TextElement el) {
  return appDefaults
    .merge(activeStyle?.text)
    .merge(el.toPartialStyle());  // non-null fields only
}
```

우선순위: **앱 기본 → .style → 요소 override** (MVP §3.7)

---

## 4. 윈도우 아키텍처

### Phase A (macOS 개발)

```
OperatorWindow
  ├── OperatorScreen (always)
  └── Navigator → OutputScreen (fullscreen route, same window)
```

- `Navigator.push` full-screen 또는 `Stack` overlay
- 키보드: `OperatorScreen` Focus

### Phase B (Windows 운영)

```
Main Process (Operator)
  │
  ├── desktop_multi_window.createWindow('output')
  │     └── OutputScreen (frameless, target monitor)
  │
  └── MonitorService.placeWindow(outputId, monitorLabel)
```

| 이벤트 | 동작 |
|--------|------|
| PlaybackState 변경 | Operator → Output 메시지 broadcast |
| Output 창 closed | `autoReconnect` → 새 Output, `isBlank: true` |
| 설정에서 모니터 변경 | Output destroy → recreate on new monitor |

---

## 5. 파일 I/O

### 5.1 작업 폴더

```
D:\hymns\                    ← workspaceFolderPath
├── default.style
├── 2024/
│   ├── 주님의_마음.sub
│   └── 할렐루야.sub
└── imports/
    └── 새찬양.txt
```

### 5.2 WorkspaceScanner

```dart
Stream<SubFileEntry> scanSubFiles(String root) async* {
  // recursive, follow links: false
  // yield SubFileEntry(path, title, previewLines)
}
```

### 5.3 Auto-save

```
onEditorChanged(SubFile sub)
  → debounce 300ms
  → sub_io.write(sub.filePath, sub)
  → on failure: snackbar + isDirty stays true
```

---

## 6. 캔버스 렌더링

### 6.1 좌표계

- 논리 해상도: **1920 × 1080**
- 저장: **percent** (0–100)
- 렌더: `left = x/100 * canvasWidth`

```dart
class SubtitleCanvas extends StatelessWidget {
  // AspectRatio(16/9) → LayoutBuilder → canvasSize
  // Stack of positioned elements sorted by zIndex
}
```

### 6.2 요소 렌더

| type | Widget |
|------|--------|
| text | `Column` of `Text`, `anchor` center → `Transform` |
| image | `Image.memory(base64Decode(data))` |
| shape | `CustomPaint` — rect, ellipse, line |

### 6.3 Editor vs Output

| | Editor | Output |
|---|--------|--------|
| Gesture | select, drag, double-tap | none |
| Selection border | yes | no |
| isBlank | preview respects | hide all elements |

---

## 7. 키보드 입력

```dart
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.arrowDown): NextSlideIntent(),
    LogicalKeySet(LogicalKeyboardKey.keyB): ToggleBlankIntent(),
    // ...
  },
  child: Actions(...),
)
```

- **Operator window only** — Output은 `IgnorePointer` + no focus
- 숫자+Enter: `DigitBuffer` (1–9, Should: two-digit)

---

## 8. 로컬 저장 (Hive)

| Box | Key | Value |
|-----|-----|-------|
| `settings` | `app` | AppSettings JSON |
| `orders` | `{orderId}` | ServiceOrder |
| `orders_index` | `list` | `[orderId, ...]` |

예배 순서 **무제한** — `orders_index`로 목록 관리

---

## 9. 플랫폼 분기

```dart
if (Platform.isWindows) {
  await MonitorService.instance.initReal();
} else {
  MonitorService.instance.useMockMonitors(); // 개발용 3개
}
```

| 기능 | macOS | Windows |
|------|-------|---------|
| MonitorService | mock | screen_retriever |
| Multi-window | optional / route | desktop_multi_window |
| File I/O | dart:io ✅ | dart:io ✅ |

---

## 10. 패키지 의존

| 패키지 | 레이어 |
|--------|--------|
| flutter_riverpod | providers |
| hive_flutter | repositories |
| google_fonts | widgets |
| file_picker | services |
| window_manager | output_window_service |
| screen_retriever | monitor_service |
| desktop_multi_window | main, output |
| path | services |

---

## 11. 테스트 가능 설계

| 모듈 | DI / 추상화 |
|------|-------------|
| `SubIo` | interface → `LocalSubIo` / `FakeSubIo` |
| `WorkspaceScanner` | root path inject |
| `MonitorService` | mock for macOS tests |
| `TxtParser` | pure function — unit test |

---

*구현 시 본 문서와 불일치 발견 시 MVP.md 우선, ARCHITECTURE 갱신.*
