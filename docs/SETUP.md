# Joowon Subtitle — 개발 환경 셋업

> Mac에서 개발 · Windows 교회 PC 배포  
> 기준: [MVP.md](./MVP.md) v0.6

---

## 1. 요구 사항

### Mac (개발)

| 항목 | 버전 |
|------|------|
| macOS | 12+ |
| Flutter | 3.24+ (stable) |
| Dart | 3.5+ |
| Xcode | 최신 (macOS desktop) |
| Git | 2.x |

### Windows (빌드·운영)

| 항목 | 버전 |
|------|------|
| Windows | 10/11 64-bit |
| Visual Studio 2022 | Desktop development with C++ |
| Flutter | CI와 동일 stable |

---

## 2. Mac 초기 셋업

### 2.1 Flutter

```bash
# Flutter 설치 확인
flutter doctor -v

# macOS desktop 활성화
flutter config --enable-macos-desktop

# doctor에서 macOS toolchain ✓ 확인
flutter doctor
```

### 2.2 프로젝트 생성 (최초 1회)

```bash
cd /Volumes/JetDrive/Projects/joowon_project/joowon_subtitle

flutter create . --project-name joowon_subtitle --platforms=macos,windows

flutter pub add flutter_riverpod
flutter pub add hive hive_flutter
flutter pub add google_fonts
flutter pub add file_picker
flutter pub add path path_provider
flutter pub add window_manager
flutter pub add screen_retriever
flutter pub add desktop_multi_window

flutter pub add --dev flutter_lints
```

### 2.3 일상 개발

```bash
flutter pub get
flutter run -d macos
```

Hot Reload: `r` / Hot Restart: `R`

### 2.4 테스트·분석

```bash
flutter analyze
flutter test
flutter test test/services/txt_parser_test.dart
```

---

## 3. Windows 빌드

> **Mac에서는 `flutter build windows` 불가.** CI 또는 Windows VM 사용.

### 3.1 GitHub Actions (권장)

`.github/workflows/build-windows.yml`:

```yaml
name: Build Windows

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - run: flutter pub get
      - run: flutter test
      - run: flutter build windows --release

      - uses: actions/upload-artifact@v4
        with:
          name: joowon-subtitle-windows
          path: build/windows/x64/runner/Release/
```

아티팩트: `joowon_subtitle.exe` + `data/` 폴더

### 3.2 Windows VM (로컬)

1. Parallels / VMware에 Windows 11
2. Flutter SDK + Visual Studio 2022 설치
3. 프로젝트 clone 후:

```powershell
flutter pub get
flutter build windows --release
```

출력: `build\windows\x64\runner\Release\`

### 3.3 교회 PC 배포

```
Release/
  joowon_subtitle.exe
  flutter_windows.dll
  data/
  ...
```

- 폴더 전체 복사 또는 Inno Setup으로 installer 생성
- 작업 폴더 예: `D:\hymns`

---

## 4. macOS 테스트용 fixture

개발용 샘플 파일 (`test/fixtures/` 또는 `dev/hymns/`):

**dev/hymns/주님의_마음.txt**

```text
주님의 마음 내게 주사
내 마음 기쁨 넘치네

거룩하신 주님 앞에
모든 것 드립니다
```

**dev/hymns/default.style** — MVP §7 예시 복사

---

## 5. IDE 설정

### VS Code / Cursor

확장:

- Dart
- Flutter

`launch.json` (macOS):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "joowon_subtitle (macOS)",
      "request": "launch",
      "type": "dart",
      "deviceId": "macos"
    }
  ]
}
```

---

## 6. 플랫폼별 개발 팁

| 상황 | Mac | Windows |
|------|-----|---------|
| 멀티 모니터 UI | mock 3 monitors | real API |
| 송출 2윈도우 | single-window route | desktop_multi_window |
| 파일 경로 | `/Users/.../dev/hymns` | `D:\hymns` |
| Luma 테스트 | ✗ | 교회 PC 또는 스위처 |

### MonitorService mock (Mac)

```dart
// 개발 중 macOS
MockMonitor('모니터 1 (1920×1080, 주)', isPrimary: true),
MockMonitor('모니터 2 (1920×1080)'),
MockMonitor('모니터 3 (1920×1080) ← 프로젝터'),
```

---

## 7. 문제 해결

| 문제 | 해결 |
|------|------|
| `flutter doctor` macOS ✗ | Xcode CLI: `xcode-select --install` |
| Windows build MSVC ✗ | VS 2022 "Desktop development with C++" |
| `desktop_multi_window` 빌드 오류 | Flutter stable 버전 맞추기, `flutter clean` |
| Hive box lock | 앱 중복 실행 종료 |
| google_fonts 오프라인 | font asset 로컬 bundle (배포 전) |

---

## 8. 브랜치·커밋 (권장)

```
main          — 안정, CI green
develop       — 통합
feature/*     — Sprint 작업
```

커밋 메시지: `feat:`, `fix:`, `test:`, `docs:` prefix

---

*환경 변경 시 본 문서 갱신.*
