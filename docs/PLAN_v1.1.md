# 주원 송출 v1.1 개발 계획

> **기준 버전:** v1.0.3  
> **작성일:** 2026-07-05  
> **근거:** v1.0.3 현장 사용 피드백  
> **관련 문서:** [MVP.md](./MVP.md) · [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md) · [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## 1. 목표

v1.0.3에서 **새찬송가 자막·검색·단축키** 기반을 마련했다. v1.1은 **예배 송출 실사용 중 발견된 운영·편집·표현 갭**을 메우는 릴리스다.

| 항목 | 내용 |
|------|------|
| **우선순위 원칙** | (1) 송출 중단·조작 불가 버그 → (2) 매 예배 반복 UX → (3) 렌더링 기반 정비 → (4) 표현·메타데이터 확장 |
| **완료 정의** | 본 문서 §6 체크리스트 통과 + Windows/macOS 수동 시나리오 |
| **목표 태그** | `v1.1.0` |

---

## 2. 피드백 요약

| ID | 요청 | 현재 상태 (v1.0.3) |
|----|------|-------------------|
| **F-01** | Windows 숫자패드(Numpad) 단축키 | `digit0`–`digit9`만 매핑, `numpad0`–`numpad9` **미매핑** |
| **F-02** | 스타일 글자 위치를 화면 위·왼쪽 끝까지 | 스타일 캔버스 `clamp(5, 95)`, 편집기는 `0–100` — **동작 불일치** |
| **F-03** | 컬러 피커 RGB 입력·스펙트럼 선택 | HEX + HSV 슬라이더 있음, **2D 스펙트럼·RGB 필드 UX 부족** |
| **F-04** | 왼쪽 영역(검색·순서) 가로 크기 변경 | `operator_screen.dart` **고정 300px** |
| **F-05** | 왼쪽 영역 내 상·하(찬양 목록 vs 예배 순서) 비율 변경 | `flex: 3 / 2` **고정** |
| **F-06** | 우클릭 메뉴가 화면 밖으로 나감 | `globalPosition` 고정 배치, **뷰포트 clamp 없음** |
| **F-07** | 슬라이드 컬러 태그 | `Slide.tag`(문자)만 존재, **색상 메타 없음** |
| **F-08** | 찬송가 절 표기 (본문 외 표기·스타일·편집) | `hymn_txt_converter`·`.sub tag` 있으나 **송출 표시·스타일 분리 미구현**, UI import는 일반 txt 파서 |
| **F-09** | 클립보드 import 시 파일명 지정 | `클립보드_{timestamp}` **자동 생성** |
| **F-10** | 송출 화면에서 마우스 포인터 숨김 | `OutputScreen`에 **cursor 설정 없음** |
| **F-11** | 찬양 검색 리스트에서 파일명(경로) 숨김 | `subtitle: relativePath` **표시 중** |
| **F-12** | 찬양 검색 리스트에서 파일명 변경 | **미구현** |
| **F-13** | 찬양 검색 리스트 새로고침(외부 파일 추가) | `rescan()`은 import 후만, **수동 버튼 없음** |

---

## 3. 개발 순서 (전체)

순서는 **의존성·리스크·사용 빈도**를 기준으로 정했다. 아래 Phase는 권장 병렬 범위이며, Phase 번호가 낮을수록 먼저 착수한다.

```
Phase 1 ─ 조작 버그·핫픽스        (F-01, F-06)           → v1.0.4 후보
Phase 2 ─ 검색·좌측 패널 UX       (F-11~13, F-04, F-05) → v1.0.5 후보
Phase 3 ─ 송출 화면 마감           (F-10)                 → v1.0.5 포함 가능
Phase 4 ─ 캔버스·스타일 기반 정비  (F-02, 렌더러 region)  → v1.1.0 선행 필수
Phase 5 ─ 컬러·슬라이드 메타       (F-03, F-07)           → v1.1.0
Phase 6 ─ 찬송가 절·import 확장    (F-08, F-09)           → v1.1.0
```

### 왜 이 순서인가

| 판단 | 이유 |
|------|------|
| **F-01·F-06을 최우선** | Windows 예배 PC에서 슬라이드 점프·태그 메뉴가 **막히면 송출 자체가 불가** |
| **F-11~13을 F-04·05보다 앞 또는 동시** | 패널 리사이즈 인프라보다 **검색·목록 동작**이 매주 체감됨. 리사이즈는 UI 골격 변경이므로 목록 UX 확정 후 레이아웃 잡는 편이 안전 |
| **F-10은 독립·소규모** | Phase 2와 병렬 가능 |
| **F-02·렌더러를 F-08보다 앞** | 절 표기는 **텍스트 박스·위치·스타일 분리**가 필요. 스타일 화면과 송출 렌더가 다르면 절 표기를 두 번 고침 |
| **F-07·F-08을 후반** | `.sub` 스키마·스타일·import·그리드 UI가 **동시에** 바뀌므로 기반 정비 후 진행 |

---

## 4. Phase별 상세

### Phase 1 — 조작 버그·핫픽스

**목표:** Windows 송출 PC에서 키보드·마우스 조작이 끊기지 않게 한다.

| # | 작업 | 상세 | 주요 파일 | 규모 |
|---|------|------|-----------|------|
| 1.1 | Numpad 단축키 매핑 | `numpad0`–`numpad9`를 `DigitIntent`에 연결. 기존 `isTextInputFocused` 가드 유지 | `operator_keyboard_shortcuts.dart` | S |
| 1.2 | Digit buffer UI (선택) | 상태바에 `digitBuffer` 표시 — numpad 동작 확인용 | `operator_status_bar.dart`, `playback_state.dart` | S |
| 1.3 | 컨텍스트 메뉴 뷰포트 clamp | `showContextMenu` 시 화면 크기 기준 left/top 보정, 하단·우측 넘침 시 flip | `slide_operator_panel.dart` | S |
| 1.4 | Windows 수동 검증 | numpad 1–9+Enter, Space, 화살표, 검색창 포커스 시 비활성 | [VERIFICATION.md](./VERIFICATION.md) 보강 | S |

**완료 조건**
- [ ] Windows에서 Numpad로 N번 슬라이드 이동
- [ ] 화면 가장자리 슬라이드 우클릭 시 메뉴 전체가 보임

**릴리스:** `v1.0.4` (핫픽스 단독 배포 가능)

---

### Phase 2 — 검색·좌측 패널 UX

**목표:** 찬양 목록을 예배 운영에 맞게 다듬고, 패널 레이아웃을 사용자가 조절하게 한다.

| # | 작업 | 상세 | 주요 파일 | 규모 |
|---|------|------|-----------|------|
| 2.1 | 검색 리스트 경로 숨김 | `listTitle`만 표시, `subtitle: relativePath` 제거 | `operator_search_panel.dart` | S |
| 2.2 | 목록 새로고침 | 툴바 또는 검색창 옆 `IconButton` → `workspaceProvider.rescan()` | `operator_search_panel.dart`, `workspace_provider.dart` | S |
| 2.3 | 파일명 변경 | 리스트 항목 컨텍스트 메뉴 또는 길게 누르기 → `.sub` 파일 rename + `rescan` + order 경로 갱신 | `workspace_scanner.dart`, `order_repository.dart` | M |
| 2.4 | 좌측 패널 가로 리사이즈 | `Row` + `VerticalDivider` 드래그 핸들, 너비 Hive 저장 (예: 240–480px) | `operator_screen.dart`, `app_settings.dart` | M |
| 2.5 | 좌측 패널 상·하 분할 | 찬양 목록/예배 순서 사이 `HorizontalDivider` 드래그, 비율 Hive 저장 | `operator_search_panel.dart` | M |

**완료 조건**
- [ ] 외부에서 `.sub` 추가 후 새로고침만으로 목록 반영
- [ ] 파일명 변경 후 예배 순서·현재 곡 경로 유지
- [ ] 패널 크기 재시작 후 유지

**의존:** Phase 1 완료 권장 (컨텍스트 메뉴 패턴 재사용)

**릴리스:** `v1.0.5` 또는 v1.1에 합류

---

### Phase 3 — 송출 화면 마감

**목표:** 프로젝터 화면에 마우스 커서가 보이지 않게 한다.

| # | 작업 | 상세 | 주요 파일 | 규모 |
|---|------|------|-----------|------|
| 3.1 | 송출 창 커서 숨김 | `OutputScreen` 루트에 `MouseRegion(cursor: SystemMouseCursors.none)` | `output_screen.dart` | S |
| 3.2 | 멀티 윈도우 확인 | Windows `desktop_multi_window` 송출 창에서도 동일 적용 | `output_window_provider.dart` | S |

**완료 조건**
- [ ] macOS·Windows 송출 전체화면에서 커서 미표시
- [ ] 조작 창에서는 커서 정상

**의존:** 없음 (Phase 1·2와 병렬 가능)

---

### Phase 4 — 캔버스·스타일 기반 정비

**목표:** 스타일 화면·편집기·송출 렌더의 **좌표·텍스트 영역 규칙을 통일**한다. 이후 절 표기·컬러 태그의 토대.

| # | 작업 | 상세 | 주요 파일 | 규모 |
|---|------|------|-----------|------|
| 4.1 | 스타일 캔버스 clamp 완화 | region 드래그 `0–100` (또는 편집기와 동일 상수), 위·왼쪽 끝 배치 가능 | `style_region_canvas.dart` | S |
| 4.2 | region width/height 편집 | 스타일 화면에서 본문 영역 리사이즈 핸들 | `style_region_canvas.dart`, `style_file.dart` | M |
| 4.3 | 렌더러 텍스트 박스 반영 | `CanvasRenderer`가 `el.width`/`el.height` 사용, anchor+box 레이아웃 | `canvas_renderer.dart`, `canvas_text_layout.dart` | L |
| 4.4 | 스타일 적용 경로 정합 | `sub_io.applyStyleToSub`, import, 편집기 overlay가 동일 rect 사용 | `sub_io.dart`, `canvas_editor.dart` | M |

**완료 조건**
- [ ] 스타일 화면에서 설정한 위·왼쪽 끝이 송출과 동일
- [ ] 편집기와 스타일 화면 미리보기 위치 일치
- [ ] 기존 `dev/hymns/새찬송가` 샘플 회귀 없음

**의존:** **F-08(절 표기), F-07(컬러 태그) 착수 전 필수**

---

### Phase 5 — 컬러 피커·슬라이드 컬러 태그

**목표:** 색 지정 UX 개선 및 슬라이드 그리드에서 색으로 구분.

| # | 작업 | 상세 | 주요 파일 | 규모 |
|---|------|------|-----------|------|
| 5.1 | 컬러 피커 스펙트럼 | 2D saturation/value 패널 + hue 슬라이더 (또는 `flutter_colorpicker` 검토) | `color_picker_row.dart` | M |
| 5.2 | RGB 입력 필드 | R/G/B (0–255) 개별 입력, HEX·HSV와 동기화 | `color_picker_row.dart`, `color_utils.dart` | S |
| 5.3 | 슬라이드 컬러 태그 스키마 | `Slide`에 `colorTag` (예: `#FF5722` 또는 팔레트 id) 추가, v2 하위 호환 | `slide_elements.dart`, `sub_file.dart` | M |
| 5.4 | 그리드·컨텍스트 메뉴 UI | 슬라이드 카드 좌측 색 띠, 우클릭 → 색 태그 선택 | `slide_operator_panel.dart` | M |

**완료 조건**
- [ ] 스펙트럼에서 색 선택 후 송출 반영
- [ ] 슬라이드 컬러 태그 저장·재로드
- [ ] `.sub` v2 기존 파일 로드 시 `colorTag` 없어도 동작

**의존:** Phase 4 권장 (그리드 레이아웃 안정 후)

---

### Phase 6 — 찬송가 절 표기·import 확장

**목표:** 본문 가사와 **절/후렴 표기**를 분리해 송출하고, import 경로를 통합한다.

#### 6.1 절 표기 — 설계안 (구현 전 확정 필요)

| 방식 | 설명 | 장점 | 단점 |
|------|------|------|------|
| **A. tag만 표시** | 현재 `Slide.tag`를 송출 화면 구석에 렌더 | 구현 빠름 | 스타일·위치 제어 제한 |
| **B. 별도 text 요소** | `type: verseLabel` 요소를 슬라이드에 추가 | 위치·폰트 독립 | `.sub` 스키마 확장 |
| **C. 스타일 region 2개** | `body` + `verseLabel` region | `.style`로 일괄 관리 | region merge 복잡 |

**권장:** **B + `.style` 기본 verseLabel 스타일** (Phase 4 region 기반 위).  
표기 예: `1절`, `후렴` — `kSlideTags` 확장 및 커스텀 입력은 후속.

| # | 작업 | 상세 | 주요 파일 | 규모 |
|---|------|------|-----------|------|
| 6.1 | 절 표기 MVP (방안 B) | 송출·미리보기에 verse label 렌더, 편집기에서 on/off·위치 | `canvas_renderer.dart`, `unified_editor_screen.dart` | L |
| 6.2 | 스타일 verseLabel 섹션 | `.style`에 `verseLabel` text 스타일 + region | `style_file.dart`, `style_screen.dart` | M |
| 6.3 | UI import → hymn 파서 | `(1)`, `후렴:` 자동 감지 또는 import 옵션 토글 | `import_flow.dart`, `import_preview_dialog.dart`, `sub_io.dart` | M |
| 6.4 | 클립보드 import 파일명 | preview dialog에 제목·파일명 필드, sanitize 후 저장 | `import_preview_dialog.dart`, `import_flow.dart` | S |
| 6.5 | 새찬송가 일괄 재변환 (선택) | `import_saechansongga.dart`로 verse label 요소 포함 재생성 | `dev/scripts/` | S |

**완료 조건**
- [ ] 새찬송가 8장 등 다절 곡에서 절 표기 송출
- [ ] 스타일에서 절 표기 글꼴·색·위치 변경
- [ ] 클립보드 import 시 사용자 지정 파일명
- [ ] txt import 시 `(1)` 구문 → tag + (선택) verse label

**의존:** **Phase 4 필수**, Phase 5와 부분 병렬 가능

**릴리스:** `v1.1.0`

---

## 5. 권장 스프린트 일정

| 스프린트 | 기간(가이드) | 범위 | 산출 |
|----------|--------------|------|------|
| **S1** | 2–3일 | Phase 1 전체 | `v1.0.4` |
| **S2** | 3–4일 | Phase 2.1–2.3 (검색 UX) | 내부 빌드 |
| **S3** | 2–3일 | Phase 2.4–2.5 + Phase 3 | 패널 리사이즈·커서 |
| **S4** | 5–7일 | Phase 4 | 렌더·스타일 통일 |
| **S5** | 3–4일 | Phase 5 | 컬러·슬라이드 태그 |
| **S6** | 5–7일 | Phase 6 | 절 표기·import |
| **S7** | 2일 | 통합 테스트·문서 | `v1.1.0` 태그 |

총 **약 3–4주** (1인 기준 가이드).

---

## 6. v1.1.0 완료 체크리스트

### 조작·송출
- [ ] F-01 Windows Numpad 슬라이드 이동
- [ ] F-06 우클릭 메뉴 화면 내 표시
- [ ] F-10 송출 화면 커서 숨김

### 좌측 패널·검색
- [ ] F-11 경로 미표시
- [ ] F-12 파일명 변경
- [ ] F-13 새로고침
- [ ] F-04 가로 리사이즈
- [ ] F-05 상·하 분할 리사이즈

### 스타일·표현
- [ ] F-02 스타일 위치 끝까지
- [ ] F-03 컬러 스펙트럼 + RGB
- [ ] F-07 슬라이드 컬러 태그
- [ ] F-08 절 표기 송출·스타일·편집

### Import
- [ ] F-09 클립보드 import 파일명

### 회귀
- [ ] `flutter test` 통과
- [ ] 새찬송가 645곡 스캔·검색
- [ ] Windows·macOS 송출 2창 동기화

---

## 7. 기술 메모 (구현 시 참고)

### F-01 Numpad 매핑 예시

```dart
// operator_keyboard_shortcuts.dart 에 추가
SingleActivator(LogicalKeyboardKey.numpad0): DigitIntent('0'),
// … numpad1 – numpad9
```

### F-02 / F-04 공통 저장소

패널 너비·분할 비율·마지막 검색어 등은 `AppSettings` + Hive에 저장 ([`app_settings_repository.dart`](../lib/repositories/app_settings_repository.dart) 패턴 재사용).

### F-08 `.sub` 하위 호환

`Slide`에 optional 필드만 추가 (`colorTag`, `verseLabel` 요소 등). `version`은 `2` 유지, 없는 필드는 무시.

### F-12 파일명 변경 시 주의

- `OrderRepository` 내 `filePath` 일괄 갱신
- 현재 재생 중인 곡이면 `playbackProvider` 경로 갱신
- macOS sandbox bookmark 경로 유지

---

## 8. 문서 갱신 계획

| 시점 | 문서 |
|------|------|
| Phase 4 착수 전 | MVP.md §3.8 위치·region, §6 `.sub` 필드 |
| Phase 6 착수 전 | MVP.md §5 import, 절 표기 정책 |
| v1.1.0 릴리스 | VERIFICATION.md 시나리오 추가, README 버전 |

---

## 9. 범위 외 (v1.1 이후)

- 작업 폴더 FSE watch 자동 새로고침
- 슬라이드 tag 사용자 정의 문자열
- Undo/Redo 전역 단축키 (MVP §4 미구현분)
- 찬양 DB 클라우드 동기화

---

*이 문서는 피드백 기반 실행 계획이다. Phase 착수 전 세부 설계가 바뀌면 본 문서를 먼저 수정한다.*
