# Joowon Subtitle

교회 찬양 가사 송출 Flutter Desktop 앱

## 문서

[docs/README.md](docs/README.md)

## 개발 실행 (macOS)

```bash
flutter pub get
flutter run -d macos
```

## 테스트

```bash
flutter analyze
flutter test
```

## 프로젝트 구조

```
lib/
  models/       # .sub, .style 데이터 모델
  services/     # 파서, 파일 I/O, 스캔
  providers/    # Riverpod 상태
  windows/      # 조작·송출 UI
  widgets/      # 캔버스, 공통 위젯
```
