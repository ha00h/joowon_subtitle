# Joowon Subtitle — 개발 계획

> 기준: [MVP.md](./MVP.md) v0.6  
> 플랫폼: Flutter Desktop (Mac 개발 / Windows 배포)  
> 작성일: 2026-06-29

---

## 1. 목표

| 항목 | 내용 |
|------|------|
| **제품** | 교회 찬양 가사 송출 데스크톱 앱 |
| **MVP 완료 정의** | [MVP.md §16](./MVP.md#16-성공-기준) + [VERIFICATION.md §5](./VERIFICATION.md#5-수용-테스트-교회-환경) 통과 |
| **1차 배포** | Windows `.exe` — 교회 자막 PC |

---

## 2. Phase 개요

```
Phase A (macOS)          Phase B (Windows)
─────────────────        ─────────────────
핵심 송출 루프              멀티 윈도우·모니터
파일·파서·순서              CI 빌드·수용 테스트
단일 창 송출               교회 PC 배포
```

| Phase | 목표 | 완료 시 할 수 있는 것 |
|-------|------|----------------------|
| **A** | macOS에서 **예배 리허설 가능** 수준 | .txt→.sub, 순서, 키보드, 미리보기+송출(단일/라우트) |
| **B** | Windows **운영 배포** | 3모니터, 자동 재연결, .exe 설치 |

---

## 3. 마일스톤

| ID | 마일스톤 | Phase | 검증 |
|----|----------|-------|------|
| **M0** | 프로젝트 셋업 | A | `flutter run -d macos` |
| **M1** | 파일 레이어 | A | [VERIFICATION §2.1](./VERIFICATION.md#21-파일--파서) |
| **M2** | 송출 MVP | A | 슬라이드 넘김 + 미리보기/송출 동기화 |
| **M3** | 편집기 MVP | A | 캔버스·.style·Undo |
| **M4** | 예배 운영 MVP | A | 순서·키보드·B·경계 넘김 |
| **M5** | Windows 송출 | B | 멀티 모니터·2윈도우 |
| **M6** | 배포 | B | CI `.exe` + 교회 수용 테스트 |

---

## 4. 작업 분해 (WBS)

### Sprint 0 — 셋업 (M0)

| # | 작업 | 산출물 |
|---|------|--------|
| 0.1 | `flutter create`, desktop enable | 프로젝트 뼈대 |
| 0.2 | 폴더 구조 (`lib/models`, `services`, …) | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| 0.3 | Riverpod, Hive, 패키지 추가 | `pubspec.yaml` |
| 0.4 | 16:9 FHD `AspectRatio` 레이아웃 | 조작 화면 골격 |
| 0.5 | `flutter_lints`, `flutter test` CI (macOS) | `.github/workflows/test.yml` |

**완료 조건:** macOS 앱 실행, 빈 16:9 캔버스 표시

---

### Sprint 1 — 파일·파서 (M1)

| # | 작업 | MVP 참조 |
|---|------|----------|
| 1.1 | `.txt` 파서 (빈 줄 1 = 슬라이드) | MVP §5 |
| 1.2 | `.sub` v2 모델 + JSON 직렬화 | MVP §6 |
| 1.3 | `.style` 모델 + 직렬화 | MVP §7 |
| 1.4 | 스타일 merge (우선순위) | MVP §3.7 |
| 1.5 | 작업 폴더 재귀 `.sub` 스캔 | MVP §3.1 |
| 1.6 | `.sub` 자동 저장 | MVP §3.1 |
| 1.7 | **단위 테스트** | [VERIFICATION §2.1](./VERIFICATION.md) |

**완료 조건:** fixture `.txt` → `.sub` round-trip, 재귀 스캔 테스트 통과

---

### Sprint 2 — 송출 코어 (M2)

| # | 작업 | MVP 참조 |
|---|------|----------|
| 2.1 | `PlaybackState` + Riverpod | ARCHITECTURE §3 |
| 2.2 | 슬라이드 렌더러 (text, FHD 16:9) | MVP §3.13 |
| 2.3 | Phase A: 앱 내 송출 라우트 또는 2패널 | MVP §2.4 Phase A |
| 2.4 | 조작↔송출 상태 동기화 | MVP §11 |
| 2.5 | 검정 배경 (Luma) | MVP §3.12 |
| 2.6 | 이전/다음 + 방향키 | MVP §4 |
| 2.7 | 찬양 검색 UI + 목록 | MVP §9.1 |

**완료 조건:** .sub 1곡 로드 → 키보드로 슬라이드 넘김 → 송출 영역 동기화

---

### Sprint 3 — 스타일·편집기 (M3)

| # | 작업 | MVP 참조 |
|---|------|----------|
| 3.1 | `.style` 불러오기·적용 UI | MVP §3.7 |
| 3.2 | text 요소 렌더 + override | MVP §3.7 |
| 3.3 | 폰트 6종 (`google_fonts`) | MVP §3.8 |
| 3.4 | 요소 선택 → 스타일 패널 | MVP §3.9 |
| 3.5 | 텍스트 더블클릭 편집 | MVP §3.9 |
| 3.6 | 드래그 위치 (x/y %) | MVP §3.9 |
| 3.7 | 슬라이드 추가/삭제/복제 | MVP §3.9 |
| 3.8 | Undo/Redo | MVP §3.9 |
| 3.9 | image base64, shape 3종 | MVP §3.10–3.11 |

**완료 조건:** .style 적용 + 요소 override, 편집 Undo 후 자동 저장

---

### Sprint 4 — 예배 운영 (M4)

| # | 작업 | MVP 참조 |
|---|------|----------|
| 4.1 | 예배 순서 CRUD (Hive) | MVP §3.4 |
| 4.2 | 곡·슬라이드 경계 넘김 | MVP §3.2 |
| 4.3 | Page Up/Down, 1–9+Enter, B, Home | MVP §4 |
| 4.4 | DnD: 검색 → 순서 | MVP §3.1 |
| 4.5 | 중복 제목 + 경로 툴팁 | MVP §3.1 |
| 4.6 | 출력 상태 표시 (곡, n/N, B) | MVP §9.1 |
| 4.7 | 설정 화면 (폴더, .style, 배경) | MVP §3.6 |

**완료 조건:** [VERIFICATION §3 — 시나리오 1~4](./VERIFICATION.md#3-통합-시나리오-테스트) macOS 통과

---

### Sprint 5 — Windows 송출 (M5)

| # | 작업 | MVP 참조 |
|---|------|----------|
| 5.1 | `desktop_multi_window` 조작+송출 | MVP §3.5 |
| 5.2 | `screen_retriever` 모니터 목록 | MVP §3.5 |
| 5.3 | `window_manager` 출력 모니터 배치 | MVP §3.5 |
| 5.4 | 모니터 미인식 경고 | MVP §3.5 |
| 5.5 | 송출 창 닫힘 → 자동 재연결 | MVP §3.5 |
| 5.6 | transparent **배경** 옵션 | MVP §3.12 |
| 5.7 | Windows VM/실기 테스트 | VERIFICATION §4 |

**완료 조건:** Windows 3모니터에서 출력 모니터 지정 + 송출 전체화면

---

### Sprint 6 — 배포·수용 (M6)

| # | 작업 | 산출물 |
|---|------|--------|
| 6.1 | GitHub Actions `flutter build windows` | `.exe` 아티팩트 |
| 6.2 | (선택) Inno Setup / MSIX | 설치 프로그램 |
| 6.3 | 교회 PC 설치·Luma 리허설 | 수용 테스트 보고 |
| 6.4 | 버그 수정·MVP 체크리스트 클로즈 | MVP §12 전항 ✅ |

**완료 조건:** [VERIFICATION §5](./VERIFICATION.md#5-수용-테스트-교회-환경) + MVP §16

---

## 5. 일정 가이드 (참고)

> 1인 개발 · 주 10~15h 기준 **대략적** 추정

| Sprint | 기간 | 누적 |
|--------|------|------|
| 0 셋업 | 3~5일 | 1주 |
| 1 파일 | 1~1.5주 | 2주 |
| 2 송출 | 1~1.5주 | 3.5주 |
| 3 편집 | 2~3주 | 6.5주 |
| 4 운영 | 1~1.5주 | 8주 |
| 5 Windows | 1.5~2주 | 10주 |
| 6 배포 | 1주 | **~11주** |

Phase A (M0~M4): **약 8주** — macOS 리허설 가능  
Phase B (M5~M6): **약 3주** — Windows 배포

---

## 6. 리스크 & 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| Mac에서 Windows 모니터 API 검증 불가 | M5 지연 | Phase A 먼저 완료, Win VM 조기 확보 |
| `desktop_multi_window` 불안정 | 송출 분리 실패 | Phase A 라우트 방식 유지, 패키지 버전 고정 |
| `.sub` base64 용량 | 대용량 파일 느림 | import 시 이미지 리사이즈 (optional 상한) |
| Flutter Windows 빌드 CI 실패 | 배포 지연 | SETUP.md CI 템플릿, 로컬 Win VM 병행 |
| 교회 PC 스펙/드라이버 | Luma 합성 이슈 | 수용 테스트 전 **리허설 1회** 필수 |

---

## 7. Definition of Done (공통)

작업 항목이 「완료」로 간주되려면:

- [ ] MVP 해당 § 요구사항 충족
- [ ] 관련 **단위/통합 테스트** 추가 또는 [VERIFICATION](./VERIFICATION.md) 수동 체크 ✅
- [ ] macOS `flutter analyze` / `flutter test` 통과
- [ ] (UI 변경) 16:9 캔버스에서 깨짐 없음
- [ ] (Windows 전용) Win 빌드에서 1회 이상 확인

---

## 8. MVP 체크리스트 매핑

[MVP.md §12](./MVP.md#12-mvp-기능-체크리스트) Must Have → Sprint

| Must Have | Sprint |
|-----------|--------|
| .sub v2, .style, txt, 자동 저장 | 1 |
| 재귀 검색, 툴팁, DnD, 순서 | 1, 4 |
| 경계 넘김, B, 키보드 | 4 |
| 폰트, 16:9, 배경 | 2, 3 |
| 캔버스 편집, Undo | 3 |
| 모니터, 재연결, 멀티 배치 | 5 |

---

*개발 중 범위 변경 시 MVP.md → 본 문서 순으로 갱신.*
