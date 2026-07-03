# Joowon Subtitle — 검증 방법

> 기준: [MVP.md](./MVP.md) v0.6  
> [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md) Sprint별 완료 조건

---

## 1. 검증 레벨

```
Level 1  단위 테스트 (Unit)        — 파서, 직렬화, style merge
Level 2  위젯/컴포넌트 테스트       — 캔버스 렌더, 키보드
Level 3  통합 시나리오 (Integration) — macOS 앱 end-to-end
Level 4  Windows 플랫폼 테스트      — 모니터, 2윈도우
Level 5  수용 테스트 (Acceptance)   — 교회 PC, Luma, 30분 리허설
```

| Level | 실행 시점 | 환경 |
|-------|-----------|------|
| 1–2 | PR / `flutter test` | Mac CI |
| 3 | Sprint 4 완료 | macOS |
| 4 | Sprint 5 완료 | Windows VM / 실기 |
| 5 | M6 배포 전 | **교회 PC** |

---

## 2. Level 1 — 단위 테스트

### 2.1 파일 / 파서

**파일:** `test/services/txt_parser_test.dart`

| ID | 케이스 | 입력 | 기대 |
|----|--------|------|------|
| T-01 | 빈 줄 1 = 슬라이드 | MVP §5 예시 txt | 3 slides |
| T-02 | 연속 빈 줄 2+ | `\n\n\n` between | 슬라이드 경계 |
| T-03 | 파일 끝 빈 줄 | trailing newlines | 마지막 슬라이드 정상 |
| T-04 | UTF-8 한글 | `할렐루야` | 인코딩 유지 |

**파일:** `test/services/sub_io_test.dart`

| ID | 케이스 | 기대 |
|----|--------|------|
| S-01 | SubFile → JSON → SubFile | round-trip 동일 |
| S-02 | image base64 encode/decode | ImageElement 유지 |
| S-03 | v1 import (slides[].lines) | v2 text element 변환 |

**파일:** `test/services/style_resolver_test.dart`

| ID | 케이스 | 기대 |
|----|--------|------|
| ST-01 | app default only | default fontSize |
| ST-02 | .style only | style fontSize |
| ST-03 | element override | element > style > app |
| ST-04 | partial override | fontSize override, color from style |

**파일:** `test/services/workspace_scanner_test.dart`

| ID | 케이스 | 기대 |
|----|--------|------|
| W-01 | flat folder | N개 .sub |
| W-02 | nested 2 depth | 재귀 탐색 |
| W-03 | duplicate title | 2 entries, different paths |

### 2.2 Playback 로직

**파일:** `test/services/playback_navigation_test.dart`

| ID | 상황 | 기대 (MVP §3.2) |
|----|------|-----------------|
| P-01 | next, mid slide | slideIndex + 1 |
| P-02 | next, last slide, has next hymn | next hymn, slide 0 |
| P-03 | prev, first slide | slideIndex unchanged |
| P-04 | next, last hymn last slide | unchanged |
| P-05 | Page Down, last hymn | no-op |
| P-06 | Page Up, first hymn | orderIndex unchanged |
| P-07 | B toggle | isBlank flip, restore slide |

---

## 3. Level 2 — 위젯 테스트

**파일:** `test/widgets/canvas_renderer_test.dart`

| ID | 케이스 | 기대 |
|----|--------|------|
| C-01 | text 2 lines | 2 Text widgets |
| C-02 | x/y 50% center | positioned center |
| C-03 | isBlank true | no elements visible |
| C-04 | zIndex order | lower behind |

---

## 4. Level 3 — 통합 시나리오 (macOS)

수동 + (선택) `integration_test/`

### 시나리오 1 — 최초 설정

| Step | 동작 | 확인 |
|------|------|------|
| 1 | 앱 실행 | 조작 화면 16:9 |
| 2 | 설정 → 작업 폴더 `dev/hymns` | 저장 후 유지 |
| 3 | `.style` 선택 | 캔버스 기본 폰트 반영 |
| 4 | 재시작 | 설정 유지 |

### 시나리오 2 — txt → sub → 송출

| Step | 동작 | 확인 |
|------|------|------|
| 1 | `.txt` 가져오기 | `.sub` 생성·목록 표시 |
| 2 | 곡 선택 | 미리보기 슬라이드 1 |
| 3 | `→` 3회 | 슬라이드 3, 송출 동기화 |
| 4 | 마지막에서 `→` | (순서 있으면) 다음 곡 |

### 시나리오 3 — 예배 순서

| Step | 동작 | 확인 |
|------|------|------|
| 1 | 검색에서 3곡 DnD → 순서 | 순서 3항목 |
| 2 | 1번 곡 송출 중 Page Down | 2번 곡 1슬라이드 |
| 3 | 앱 재시작 | 순서 유지 (Hive) |

### 시나리오 4 — 편집·자동 저장

| Step | 동작 | 확인 |
|------|------|------|
| 1 | 텍스트 더블클릭 수정 | 화면 반영 |
| 2 | Ctrl+Z | 되돌림 |
| 3 | 앱 재시작 → 동일 .sub | 저장 내용 동일 |
| 4 | 요소 fontSize override | .style과 다르게 표시 |

### 시나리오 5 — B blank

| Step | 동작 | 확인 |
|------|------|------|
| 1 | 슬라이드 표시 중 `B` | 송출만 숨김, 미리보기 유지 |
| 2 | `B` again | 직전 슬라이드 복원 |
| 3 | 상태 표시 | `B:ON` / `B:OFF` |

---

## 5. Level 4 — Windows 플랫폼 테스트

**환경:** Windows 10/11, 모니터 2개 이상 (3개 권장)

| ID | 케이스 | 확인 |
|----|--------|------|
| WIN-01 | 모니터 목록 표시 | 표시명 2개+ |
| WIN-02 | 출력 모니터 선택 → 송출 창 | 해당 모니터 전체화면 |
| WIN-03 | 모니터 미연결 mock | 경고창 |
| WIN-04 | 송출 창 X 닫기 | 자동 재연결, 빈 화면 |
| WIN-05 | 재연결 후 슬라이드 넘김 | 송출 동기화 |
| WIN-06 | black 배경 | #000 송출 |
| WIN-07 | transparent 옵션 | (가능 시) 투명 확인 |

---

## 6. Level 5 — 수용 테스트 (교회 환경)

**사전 조건**

- [ ] Windows `.exe` 설치
- [ ] 작업 폴더 `D:\hymns` + `.sub` 3곡 이상
- [ ] `.style` 1개
- [ ] 3모니터 + 스위처 Luma 설정 완료

### 6.1 리허설 체크리스트 (30분)

| # | 항목 | Pass |
|---|------|------|
| A1 | 출력 모니터 = 프로젝터 | ☐ |
| A2 | Luma로 검정 배경 제거, 가사만 합성 | ☐ |
| A3 | 예배 순서 5곡 구성·저장 | ☐ |
| A4 | 곡 전환 (Page Down) 5회 무오류 | ☐ |
| A5 | 슬라이드 전환 (→) 50회+ 무오류 | ☐ |
| A6 | B blank 기도 시뮬레이션 3회 | ☐ |
| A7 | 1–9+Enter 슬라이드 점프 | ☐ |
| A8 | 송출 창 닫기 → 자동 복구 | ☐ |
| A9 | 긴급 가사 수정 → 자동 저장 → 반영 | ☐ |
| A10 | 30분 동안 크래시·멈춤 없음 | ☐ |

### 6.2 실패 시

| 증상 | 기록 | 조치 |
|------|------|------|
| | 재현 step | 이슈 등록 → DEVELOPMENT_PLAN 리스크 |

---

## 7. MVP Must Have — 검증 매트릭스

[MVP §12](./MVP.md#12-mvp-기능-체크리스트) 전항목:

| Must Have | L1 | L3 | L4 | L5 |
|-----------|----|----|----|-----|
| .sub v2 + image | S-01,02 | 시나리오 2 | | |
| .style + override | ST-* | 시나리오 4 | | A9 |
| .txt, auto-save | T-*, S-* | 2, 4 | | |
| 재귀 검색, tooltip | W-* | 3 | | |
| DnD 순서 | | 3 | | A3 |
| 경계 넘김 | P-* | 2, 3 | | A4,A5 |
| B blank | P-07 | 5 | | A6 |
| 키보드 §4 | P-* | 2–5 | | A5,A7 |
| 폰트 6종 | | 4 | | |
| 16:9 FHD | C-* | 1 | | |
| black/transparent | | | WIN-06,07 | A2 |
| 캔버스 편집 | | 4 | | A9 |
| Undo/Redo | | 4 | | |
| 모니터, 경고 | | | WIN-01,03 | A1 |
| auto reconnect | | | WIN-04,05 | A8 |
| multi monitor | | | WIN-02 | A1 |

---

## 8. CI 파이프라인

```yaml
# .github/workflows/test.yml (macOS)
- flutter analyze
- flutter test

# .github/workflows/build-windows.yml
- flutter test
- flutter build windows --release
```

PR merge 조건: **analyze + test green**

---

## 9. 테스트 fixture 위치

```
test/
├── fixtures/
│   ├── sample.txt
│   ├── sample.sub
│   ├── sample.style
│   └── nested/
│       └── deep.sub
├── services/
│   ├── txt_parser_test.dart
│   ├── sub_io_test.dart
│   └── ...
└── widgets/
    └── canvas_renderer_test.dart
```

---

## 10. 완료 판정

**MVP Release Ready** = 아래 전부 ✅

- [ ] Level 1: `flutter test` 100% pass (핵심 모듈)
- [ ] Level 3: 시나리오 1~5 pass (macOS)
- [ ] Level 4: WIN-01~07 pass (Windows)
- [ ] Level 5: A1~A10 pass (교회 PC 30분)
- [ ] [MVP §16](./MVP.md#16-성공-기준) 전항목

---

*새 기능 추가 시 본 문서에 테스트 케이스 ID 추가.*
