# Joowon Subtitle — MVP 명세서

> 교회 예배용 **찬양 가사 송출** 데스크톱 애플리케이션  
> 버전: MVP v0.6 · 작성일: 2026-06-29

---

## 1. 프로젝트 개요

### 1.1 목적

예배 중 찬양 가사를 **대형 화면(빔·TV)** 에 송출하고, 송출 담당자가 **데스크톱 앱**으로 곡을 선택·순서를 정리·슬라이드를 넘기는 도구를 만든다.

### 1.2 MVP 범위

| 포함 | 제외 (향후) |
|------|-------------|
| 찬양 가사 저장·편집 (`.sub`) | 성경 구절 송출 |
| `.txt` 가져오기 → `.sub`로 저장 | 원격 조어(태블릿·폰) |
| 작업 폴더 + **하위 폴더** `.sub` 검색 | 사용자 계정·클라우드 동기화 |
| 예배 순서 — **개수 무제한**, 파일 내보내기 없음 | 배경 영상 재생 |
| **스타일 파일** (`.style`) — 전역 일괄 적용 | |
| 슬라이드 송출 + 곡·슬라이드 경계 넘김 | |
| **B키** 빈 화면(송출 숨기기) 토글 | |
| 멀티 모니터 — 출력 모니터 선택 | |
| 설정 (모니터·폴더·기본값) | |
| 송출 스타일 + **폰트 5~6종** (무료) | |
| 글자 위치·도형·**이미지(.sub 내장)** | |
| 캔버스 에디팅 + Undo/Redo | |
| 배경: **검정(기본) + 투명(추가 시도)** | |
| 캔버스·출력 **16:9 FHD** | |
| `.sub` **자동 저장** | |
| 송출 창 **자동 재연결** | |
| 드래그앤드롭 → 예배 순서 | |
| 로컬 저장(오프라인) | macOS/Linux 교회 PC |

### 1.3 한 줄 정의

**찬양 가사를 `.sub`로 관리하고, `.style`로 스타일을 통일하며, 예배 순서대로 FHD 16:9 슬라이드를 선택 모니터에 송출하는 Flutter 데스크톱 앱**

---

## 2. 사용자·사용 시나리오

### 2.1 역할

| 역할 | 설명 |
|------|------|
| **송출 담당** | 곡 검색, 순서 편집, 슬라이드·스타일 편집, 송출 제어 |
| **회중** | 프로젝터/TV에 표시되는 가사·그래픽만 봄 |

### 2.2 대표 시나리오

1. **최초 설정**: 작업 폴더·출력 모니터·`.style` 파일 지정
2. 예배 전: `.sub` 검색(하위 폴더 포함), 드래그로 예배 순서 구성
3. 예배 전: `.style` 적용 후 슬라이드별 override 편집 (자동 저장)
4. 예배 중: **[송출 창 열기]** → 선택 모니터 FHD 전체화면
5. 예배 중: 방향키·Page Up/Down·숫자+Enter·B 로 제어
6. 예배 중: 송출 창 닫혀도 자동 재연결 (빈 화면 상태)

### 2.3 환경 — 3모니터

```
[모니터 1]  조작 화면
[모니터 2]  (선택) 반주/방송
[모니터 3]  송출 — 설정에서 지정
```

- 모니터 미인식 시 **경고창** 표시
- 모니터 선택: **표시명** 기준 (보조 정보)

### 2.4 플랫폼 전략 (Flutter Desktop)

| 항목 | 결정 |
|------|------|
| **프레임워크** | **Flutter 3.x Desktop** |
| **개발 환경** | **macOS** (일상 개발·UI·편집기) |
| **운영 환경** | **Windows 10/11** (교회 자막 PC) |
| **배포 형태** | Windows 설치 파일 (`.exe` / `.msi`) |

#### 왜 Flutter Desktop인가

- MVP v0.5 시점 요구(멀티 모니터, 자동 저장, 송출 창 재연결, 파일 시스템)는 **브라우저보다 데스크톱**에 적합
- 개발자 **Flutter 숙련** → Tauri/React 신규 학습 대비 **구현 속도 유리**
- `.sub` / `.style` / 캔버스 / 키보드 등 **비즈니스 로직**은 플랫폼과 무관하게 본 문서 그대로 적용

#### Mac 개발 / Windows 운영 역할 분담

| | macOS (개발) | Windows (교회 PC) |
|---|-------------|-------------------|
| UI·캔버스·편집기 | ✅ 메인 개발 | ✅ 동일 빌드 |
| `.sub` / `.style` / `.txt` | ✅ | ✅ |
| 예배 순서·키보드·B blank | ✅ | ✅ |
| **멀티 모니터·송출 창 배치** | △ UI·더미만 | ✅ **기준 환경·수용 테스트** |
| **Luma + 스위처** | ✗ | ✅ **필수 리허설** |
| **Windows `.exe` 빌드** | ✗ (로컬 불가) | ✅ CI 또는 VM |

> Mac에서는 **Windows 전용 기능을 100% 검증할 수 없다.**  
> GitHub Actions 등으로 Windows 빌드 후 **교회 PC(또는 Win VM)에서 반드시 1회 이상** 송출·모니터 테스트.

#### 개발·빌드 흐름

```
[Mac]
  flutter run -d macos
  → UI, .sub, .style, 캔버스, 키보드, 예배 순서 개발 (Hot Reload)

[CI: windows-latest]  또는  [Windows VM]
  flutter build windows
  → joowon_subtitle.exe / installer

[교회 Windows PC]
  설치 → 작업 폴더 지정 (예: D:\hymns)
  → 3모니터 + 스위처 Luma 최종 리허설
```

#### 구현 단계 (플랫폼)

| Phase | 범위 | 환경 |
|-------|------|------|
| **A** | 송출 루프 — `.txt`/`.sub`, 순서, 키보드, 검정 배경, 미리보기 | macOS 단일 창 (또는 앱 내 풀스크린 라우트) |
| **B** | 멀티 윈도우, 모니터 선택, 자동 재연결, Windows 배포 | Windows 실기 + CI 빌드 |

#### Flutter 프로젝트 구조 (참고)

```
lib/
  models/          # SubFile, StyleFile, SlideElement …
  services/        # parser, file_io, auto_save, monitor
  state/           # playback, order, settings
  windows/
    operator/      # 조작 UI
    output/        # 송출 UI
  widgets/         # canvas, text_block, shape, …
```

#### Windows 전용 기능 — Mac 개발 시

- 모니터 목록 API 미동작 시 → **더미 모니터 1/2/3** 으로 UI만 먼저 구현
- `screen_retriever` + `window_manager` 연동은 **Windows 빌드**에서 활성화
- 플랫폼 분기: `Platform.isWindows` / `Platform.isMacOS`

---

## 3. 핵심 기능

### 3.1 찬양 관리

- **저장 형식**: `.sub` (§5)
- **자동 저장**: `.sub` 편집 시 즉시 저장 (별도 저장 버튼 불필요, 수동 저장도 가능)
- **검색**: 작업 폴더 **하위 폴더 재귀** — `.sub` 제목·가사
- **중복 제목**: 동일 제목 파일 **모두 표시**, 마우스 오버 시 **폴더 경로 툴팁**
- **드래그앤드롭**: 검색 결과 → 예배 순서에 드롭하여 추가
- **입력**: 직접 입력 또는 `.txt` 가져오기 → `.sub`

### 3.2 슬라이드·곡 넘김 경계

| 상황 | 동작 |
|------|------|
| 슬라이드 **다음** (마지막 슬라이드) | **다음 찬양** 1번 슬라이드 |
| 슬라이드 **이전** (첫 슬라이드) | **첫 슬라이드 고정** (이동 없음) |
| 예배 순서 **다음** (마지막 찬양·마지막 슬라이드) | **마지막 슬라이드 고정** |
| **Page Up** | 이전 찬양 1슬라이드 (첫 찬양이면 **첫 찬양 유지**) |
| **Page Down** | 다음 찬양 1슬라이드 (마지막 찬양이면 **반응 없음**) |

### 3.3 빈 화면 (Black)

- **`B` 키**: 송출 화면만 **숨김/복원 토글** (조작 화면·미리보기는 유지)
- 숨김 상태: 송출 창은 **검정(또는 투명)** — 아무 요소도 렌더하지 않음
- 다시 `B` → 직전 슬라이드 복원

### 3.4 예배 순서

- 찬양 순서 **개수 무제한**
- 추가·삭제·재정렬·드래그앤드롭
- **로컬 DB** 저장 (파일 내보내기 **없음**)
- 여러 예배 순서 목록 저장 가능 (이름별)

### 3.5 멀티 모니터 & 송출 창

| 기능 | 설명 |
|------|------|
| **모니터 목록** | 연결된 모니터 **표시명** 표시 |
| **출력 모니터 선택** | 설정에서 1개 지정 |
| **미인식** | 듀얼/멀티 모니터 API 실패 시 **경고창** |
| **송출 창 닫힘** | **자동 재연결** — 새 창 열기, **빈 화면** 상태로 송출 |
| **출력 모니터 변경** | 설정에서 새 모니터 선택 → **송출 창 재배치·송출** |

**기술**: `screen_retriever` + `window_manager` + `desktop_multi_window` (§11)

### 3.6 설정

| 설정 항목 | 설명 |
|-----------|------|
| **출력 모니터** | 표시명으로 선택 |
| **작업 폴더** | `.sub` / `.style` 검색 루트 |
| **기본 `.style` 파일** | 앱 시작 시 적용할 스타일 |
| **송출 배경** | `black` (기본) \| `transparent` (추가 시도) |
| **송출 창** | 전체화면 자동, ESC 잠금 등 |

설정은 **Hive / shared_preferences**에 저장, 앱 재시작 후 유지.

### 3.7 스타일 파일 (`.style`)

**한 번에 모든 슬라이드·요소에 적용**하는 전역 스타일. `.sub`의 요소별 값은 **override**.

```
적용 우선순위 (낮 → 높):
  1. 앱 기본값
  2. .style 파일 (전역)
  3. .sub 내 hymn-level style (선택, 향후)
  4. 요소별 필드 (element override) ← 최우선
```

| 항목 | 설명 |
|------|------|
| **확장자** | `.style` |
| **형식** | JSON (UTF-8) |
| **내용** | fontFamily, fontSize, fontWeight, color, textShadow, defaultTextPosition 등 |
| **적용** | 불러오기 시 모든 `.sub` 슬라이드 렌더에 반영 |
| **override** | 요소에 `fontSize` 등 개별 값 있으면 그 값 사용 |

### 3.8 폰트

**저작권-free(OFL 등) 대표 폰트 5~6종** 내장:

| fontFamily | 이름 | 비고 |
|------------|------|------|
| `Noto Sans KR` | Noto Sans | 범용 고딕 |
| `Noto Serif KR` | Noto Serif | 명조 계열 |
| `Nanum Gothic` | 나눔고딕 | OFL |
| `Nanum Myeongjo` | 나눔명조 | OFL |
| `Black Han Sans` | 검은고딕 | 제목·강조 |
| `Do Hyeon` | 도현 | 디스플레이 |

- **텍스트 편집·스타일 패널**에서 폰트 선택
- `.style` / 요소별 `fontFamily` override 가능
- 웹폰트(Google Fonts 또는 로컬 asset)로 번들

### 3.9 송출 스타일 & 캔버스 에디팅

| 항목 | 설명 |
|------|------|
| **요소 선택** | 클릭 → **스타일 패널**이 해당 요소에 적용 |
| **텍스트 편집** | **더블클릭** → 줄 내용 인라인 편집 |
| **슬라이드** | 추가 / 삭제 / **복제** |
| **Undo / Redo** | `Ctrl+Z` / `Ctrl+Shift+Z` — 편집 필수 편의 |
| **글자** | 크기·굵기·그림자·**폰트**·색 |
| **위치** | 드래그 + x/y(%) |
| **도형** | rect, ellipse, line (3종) |
| **이미지** | `.sub` **내장** (§3.10) |
| **레이어** | z-index 앞/뒤 |

### 3.10 이미지 정책

| 항목 | 정책 |
|------|------|
| **저장** | `.sub` JSON **내장** — `data:image/png;base64,...` 또는 `imageData` + `mimeType` |
| **외부 경로** | MVP에서 **미사용** |
| **용량** | 큰 이미지는 편집 시 리사이즈 권장 (구현 시 상한 optional) |

### 3.11 도형 정책

| shapeType | 설명 |
|-----------|------|
| `rect` | 사각형 |
| `ellipse` | 타원 |
| `line` | 직선 |

### 3.12 배경 — 검정 + 투명

| 모드 | 설명 |
|------|------|
| **black** (기본) | 송출 배경 `#000` — **스위처 Luma Key** 로 배경 제거·합성 |
| **transparent** | `background: transparent` **추가 시도** — OBS Browser Source 등에서 활용 |

- 교회 환경: **검정 배경 + Luma** 가 주 사용
- 투명은 옵션으로 설정에서 선택

### 3.13 캔버스·출력 비율

- **1920×1080 (16:9 FHD)** 기준
- 미리보기·송출·좌표계 모두 **16:9** 캔버스
- 좌표: 캔버스 **백분율(%)** — FHD 기준 비율 유지

---

## 4. 키보드 단축키

| 키 | 동작 |
|----|------|
| `↑` `←` | **이전** 슬라이드 |
| `↓` `→` | **다음** 슬라이드 |
| `Space` | **다음** 슬라이드 (선택) |
| `1`~`9` + `Enter` | 현재 곡 **N번 슬라이드**로 바로 이동 (1-based) |
| `B` | **빈 화면** 토글 (송출만 숨김) |
| `Page Up` | **이전 찬양** 1슬라이드 (첫 찬양이면 유지) |
| `Page Down` | **다음 찬양** 1슬라이드 (마지막이면 **반응 없음**) |
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` | Redo |
| `Home` | 현재 곡 1슬라이드 (선택) |

> **조작 윈도우** 포커스 시 동작. 송출 윈도우는 키 입력 미수신(조작에서 제어).

---

## 5. 텍스트 파일(.txt) 가져오기

### 5.1 슬라이드 구분

- **빈 줄 1줄** → 새 슬라이드
- 연속 빈 줄 2줄 이상도 슬라이드 경계

### 5.2 변환

```
.txt 파싱 → text 요소 슬라이드 → .sub 저장 (자동)
기본 위치·스타일: .style 또는 앱 기본값
```

---

## 6. `.sub` 파일 형식

### 6.1 개요

| 항목 | 내용 |
|------|------|
| **확장자** | `.sub` |
| **인코딩** | UTF-8 |
| **형식** | JSON |
| **version** | `2` |

### 6.2 예시

```json
{
  "format": "joowon-subtitle",
  "version": 2,
  "title": "주님의 마음",
  "slides": [
    {
      "elements": [
        {
          "type": "text",
          "id": "t1",
          "lines": ["주님의 마음 내게 주사", "내 마음 기쁨 넘치네"],
          "x": 50,
          "y": 45,
          "anchor": "center",
          "fontFamily": "Noto Sans KR",
          "fontSize": 72,
          "fontWeight": 700,
          "color": "#FFFFFF",
          "textShadow": "2px 2px 8px rgba(0,0,0,0.8)",
          "zIndex": 1
        }
      ]
    },
    {
      "elements": [
        {
          "type": "image",
          "id": "img1",
          "data": "iVBORw0KGgoAAAANSUhEUg...",
          "mimeType": "image/png",
          "x": 10,
          "y": 10,
          "width": 15,
          "height": 15,
          "opacity": 0.8,
          "zIndex": 0
        }
      ]
    }
  ]
}
```

### 6.3 image 필드

| 필드 | 설명 |
|------|------|
| `data` | base64 인코딩 이미지 본문 |
| `mimeType` | `image/png` \| `image/jpeg` \| `image/webp` |
| `width`, `height` | 캔버스 대비 **%** |

> v0.4 `src` 경로 방식은 **폐기**. import 시 경로-only 파일은 base64 변환 또는 재첨부 유도.

### 6.4 text 추가 필드

| 필드 | 설명 |
|------|------|
| `fontFamily` | §3.8 목록 중 하나 (override) |

---

## 7. `.style` 파일 형식

```json
{
  "format": "joowon-subtitle-style",
  "version": 1,
  "name": "주일예배 기본",
  "text": {
    "fontFamily": "Noto Sans KR",
    "fontSize": 72,
    "fontWeight": 700,
    "color": "#FFFFFF",
    "textShadow": "2px 2px 8px rgba(0,0,0,0.8)",
    "defaultPosition": { "x": 50, "y": 50 }
  },
  "output": {
    "backgroundMode": "black"
  }
}
```

- 작업 폴더 또는 하위에서 `.style` 검색·선택
- 적용 시 override 없는 모든 text 요소에 일괄 반영

---

## 8. 화면 표시 정책

| 항목 | 정책 |
|------|------|
| 캔버스 | **1920×1080 논리 좌표**, UI는 16:9 비율 유지 |
| 좌표 | **%** (0–100) |
| 배경 | black (Luma) 또는 transparent (옵션) |
| 스타일 | `.style` → 요소 override |
| 송출 숨김 | `B` — 요소 미렌더 |

---

## 9. 화면 구성 (와이어프레임)

### 9.1 조작 화면

```
┌──────────────────────────────────────────────────────────────────┐
│  Joowon Subtitle  [작업 폴더] [.style ▼] [송출 창] [⚙ 설정]       │
├─────────────────────────┬────────────────────────────────────────┤
│  ■ 찬양 검색 (하위 포함)  │  ■ 캔버스 16:9                         │
│  [___________] 🔍       │  [T][▢][🖼]  Undo Redo  레이어↑↓       │
│  · 주님의 마음  ← tooltip│  ┌──────────────────────────────────┐  │
│    /hymns/2024/...      │  │ 16:9 FHD 미리보기                 │  │
│  · 주님의 마음  (dup)   │  └──────────────────────────────────┘  │
│  (드래그 → 순서)         │  폰트 [Noto Sans KR ▼] 크기 굵기 그림자  │
├─────────────────────────┤  X[50%] Y[45%]                          │
│  ■ 예배 순서             │  ■ 출력: 주님의 마음 2/5 | 모3 ● | B:OFF │
│  1. 주님의 마음      ◀  │  [◀][▶]  슬라이드+/- 복제               │
│  [+ 추가]               │                                        │
└─────────────────────────┴────────────────────────────────────────┘
```

### 9.2 설정

- 출력 모니터 (표시명 라디오)
- 작업 폴더
- 기본 `.style`
- 송출 배경: black / transparent
- 모니터 미인식 시 경고 문구

---

## 10. 데이터 모델

> Dart 클래스로 구현. 아래는 필드 참고용 (TypeScript 표기).

```typescript
interface AppSettings {
  workspaceFolderPath: string;       // 작업 폴더 절대 경로
  outputMonitorLabel: string | null; // 표시명
  defaultStylePath?: string;
  outputBackgroundMode: 'black' | 'transparent';
  autoFullscreen: boolean;
  autoReconnectOutput: boolean;
}

interface StyleFile {
  format: 'joowon-subtitle-style';
  version: 1;
  name: string;
  text: {
    fontFamily: string;
    fontSize: number;
    fontWeight: number;
    color: string;
    textShadow: string;
    defaultPosition: { x: number; y: number };
  };
  output?: { backgroundMode: 'black' | 'transparent' };
}

interface TextElement {
  type: 'text';
  id: string;
  lines: string[];
  x: number; y: number;
  anchor?: 'center' | 'top-left';
  fontFamily?: string;   // override
  fontSize?: number;
  fontWeight?: number;
  color?: string;
  textShadow?: string;
  zIndex: number;
}

interface ImageElement {
  type: 'image';
  id: string;
  data: string;          // base64
  mimeType: 'image/png' | 'image/jpeg' | 'image/webp';
  x: number; y: number;
  width: number; height: number;
  opacity?: number;
  zIndex: number;
}

interface PlaybackState {
  hymnId: string | null;
  hymnTitle: string | null;
  slideIndex: number;
  totalSlides: number;
  orderIndex: number;    // 예배 순서 내 찬양 index
  isBlank: boolean;      // B키 빈 화면
  outputConnected: boolean;
  updatedAt: number;
}

interface ServiceOrder {
  id: string;
  name: string;
  items: { hymnId: string; title: string; filePath: string }[];
  updatedAt: string;
}
// ServiceOrder 개수 무제한
```

### 10.1 저장

| 데이터 | 저장소 |
|--------|--------|
| **AppSettings** | `shared_preferences` 또는 Hive |
| `.sub` | 작업 폴더 (**자동 저장**, `dart:io`) |
| `.style` | 작업 폴더 |
| 예배 순서 (무제한) | Hive / SQLite |
| 송출 상태 | 조작↔송출 윈도우 간 **공유 상태** (Riverpod + MethodChannel 등) |

---

## 11. 기술 스택 (Flutter Desktop)

| 영역 | 선택 |
|------|------|
| **프레임워크** | Flutter 3.x Desktop |
| **언어** | Dart |
| **상태 관리** | Riverpod (또는 Bloc) |
| **캔버스** | 16:9 FHD — `Stack` + `AspectRatio` + `GestureDetector` |
| **폰트** | `google_fonts` (OFL 6종) |
| **이미지** | base64 in `.sub` → `Image.memory` |
| **파일** | `dart:io` — 재귀 `.sub` 스캔, 자동 저장 |
| **폴더 선택** | `file_picker` |
| **DnD** | Flutter `Draggable` / `DragTarget` |
| **Undo/Redo** | 커맨드 스택 (커스텀 또는 패키지) |
| **멀티 모니터** | `screen_retriever` + `window_manager` |
| **멀티 윈도우** | `desktop_multi_window` |
| **조작↔송출 동기화** | 공유 Provider + 윈도우 간 메시지 |
| **송출 재연결** | 송출 윈도우 dispose 감지 → 재생성 (팝업 차단 없음) |
| **로컬 DB** | Hive 또는 SQLite (`sqflite` + `sqflite_common_ffi`) |

### 11.1 주요 패키지

| 패키지 | 용도 |
|--------|------|
| `window_manager` | 윈도우 위치·크기·전체화면·프레임 제거 |
| `screen_retriever` | 모니터 목록·표시명·해상도 |
| `desktop_multi_window` | 조작 + 송출 2윈도우 |
| `google_fonts` | Noto Sans KR 등 |
| `file_picker` | 작업 폴더·`.txt` 가져오기 |
| `path` / `path_provider` | 경로 처리 |
| `hive` / `hive_flutter` | 설정·예배 순서 |

### 11.2 Mac 개발 / Windows 빌드

| 단계 | 명령 / 환경 |
|------|-------------|
| Mac 일상 개발 | `flutter run -d macos` |
| Mac Windows exe | **불가** — Mac에서 `flutter build windows` 지원 안 함 |
| Windows 빌드 | **GitHub Actions** `windows-latest` → `flutter build windows` |
| 대안 | Parallels / VMware Windows VM에서 로컬 빌드 |
| 수용 테스트 | 교회 PC 또는 Win VM — 3모니터·Luma **필수** |

### 11.3 플랫폼별 주의

| 항목 | macOS (개발) | Windows (운영) |
|------|-------------|----------------|
| 멀티 윈도우 | 동작 확인용 | **운영 환경** |
| 모니터 API | 제한적·레이아웃 상이 | **기준** |
| 투명 배경 | 테스트 가능 | Luma 사용 시 **black 권장** |
| `.exe` 배포 | — | Inno Setup / MSIX 등 (선택) |

---

## 12. MVP 기능 체크리스트

### Must Have

- [ ] `.sub` v2 + **이미지 base64 내장**
- [ ] `.style` 파일 + override 우선순위
- [ ] `.txt` → `.sub`, **자동 저장**
- [ ] 작업 폴더 **재귀** 검색, 중복 제목 + **경로 툴팁**
- [ ] 검색 → 예배 순서 **드래그앤드롭**
- [ ] 예배 순서 **무제한** (내보내기 없음)
- [ ] 곡·슬라이드 **경계 넘김** (§3.2)
- [ ] **B** 빈 화면 토글
- [ ] **키보드** (§4 전체)
- [ ] **폰트 6종** + 텍스트/스타일 패널
- [ ] 16:9 FHD 캔버스·출력
- [ ] 배경 black + transparent 옵션
- [ ] 요소 선택 → 스타일 패널, 텍스트 더블클릭 편집
- [ ] 슬라이드 추가/삭제/복제
- [ ] **Undo / Redo**
- [ ] 출력 모니터 **표시명** 선택, 미인식 **경고**
- [ ] 송출 창 **자동 재연결** (빈 화면)
- [ ] 멀티 모니터 송출 배치

### Should Have

- [ ] txt 가져오기 미리보기
- [ ] 숫자 10+ 슬라이드 이동 (두 자리 입력)

### Could Have (이후)

- [ ] macOS/Linux 교회 PC 대응
- [ ] 요소 회전
- [ ] 스타일 프리셋 빠른 전환 UI

---

## 13. 개발 단계

| 단계 | 작업 |
|------|------|
| **0** | `flutter create` — desktop 활성화, FHD 16:9 레이아웃 |
| **1** | txt 파서, `.sub` / `.style` 직렬화 (Dart) |
| **2** | 작업 폴더 재귀 스캔, 자동 저장 (`dart:io`) |
| **3** | `.style` 적용 + override 렌더 |
| **4** | 송출 UI, black/transparent, 조작↔송출 상태 동기화 |
| **5** | 캔버스 에디터, 폰트, Undo/Redo |
| **6** | 넘김 경계, 키보드, B blank |
| **7** | `desktop_multi_window` + 모니터, 자동 재연결 (Windows) |
| **8** | DnD, 예배 순서, UX |
| **9** | GitHub Actions Windows 빌드 + 교회 PC 수용 테스트 |

---

## 14. 파일 작성 가이드

### `.txt`

- UTF-8, 슬라이드 사이 빈 줄 1줄 → `.sub` 자동 변환·저장

### `.sub`

- JSON v2, 이미지는 **파일 내 base64**
- 편집 시 **자동 저장**

### `.style`

- 작업 폴더에 보관, 앱에서 선택 적용
- 요소 개별 수정 시 override

---

## 15. 확정 사항

| 항목 | 결정 |
|------|------|
| 배경 | **검정(기본, Luma)** + **투명(옵션)** |
| 이미지 | **`.sub` 내장** (base64) |
| 슬라이드 다음(마지막) | 다음 찬양 1슬라이드 |
| 슬라이드 이전(첫) | 첫 슬라이드 고정 |
| 순서 끝 다음 | 마지막 슬라이드 고정 |
| B | 송출만 숨김 토글 |
| 폰트 | OFL 6종, 텍스트 편집 시 선택 |
| 예배 순서 | **무제한**, 파일 내보내기 **없음** |
| 검색 | **하위 폴더**, 중복 제목 + 경로 툴팁, **DnD** |
| 편집 | 선택·더블클릭·슬라이드 CRUD·**Undo/Redo** |
| 스타일 | **`.style` 파일** + 요소 override |
| 캔버스 | **FHD 16:9** |
| 저장 | **`.sub` 자동 저장** |
| 송출 창 | 닫히면 **자동 재연결**(빈 화면) |
| 모니터 | **표시명** 선택, 미인식 **경고** |
| **플랫폼** | **Flutter Desktop** — Mac 개발 / **Windows** 교회 PC 배포 |
| **Windows 빌드** | GitHub Actions 또는 Win VM |

---

## 16. 성공 기준

- [ ] `.style` 적용 + 요소 override 동작
- [ ] 마지막 슬라이드 → 다음 찬양, B 토글, Page Up/Down
- [ ] 하위 폴더 검색, 중복 제목 툴팁, DnD 순서 추가
- [ ] 편집 Undo/Redo, 자동 저장 후 재열기 동일
- [ ] 송출 창 닫았다 자동 재연결
- [ ] Windows `.exe` 설치 후 교회 PC 3모니터·Luma 30분 리허설 무중단

---

## 17. 관련 문서

| 문서 | 설명 |
|------|------|
| [docs/README.md](./README.md) | 문서 목록·읽는 순서 |
| [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md) | Sprint·마일스톤·WBS |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 모듈·상태·윈도우 구조 |
| [SETUP.md](./SETUP.md) | Mac 셋업·Windows CI |
| [VERIFICATION.md](./VERIFICATION.md) | 단위/통합/수용 테스트 |

---

*이 문서는 MVP v0.6 구현 기준이다. 플랫폼: Flutter Desktop.*
