# 주원 송출

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

## 업데이트 알림

앱은 **GitHub Releases API**로 새 버전을 확인하고, zip 배포 방식에 맞게 **다운로드 페이지를 여는 소프트 알림**만 제공합니다. (자동 설치 없음)

### 동작 방식

| 항목 | 내용 |
|------|------|
| 버전 소스 | `pubspec.yaml` → 빌드 시 `package_info_plus`로 읽음 |
| 최신 버전 조회 | `GET /repos/ha00h/joowon_subtitle/releases/latest` |
| 비교 | `pub_semver`로 현재 버전과 릴리스 태그(`v1.0.0` → `1.0.0`) 비교 |
| 다운로드 | OS별 zip asset URL (없으면 릴리스 페이지) → `url_launcher`로 브라우저 열기 |

### 사용자 경험

- **조작 창만** 확인 (송출 창 `OutputApp`은 업데이트 UI 없음)
- 앱 시작 후 **4초 지연** 뒤 백그라운드 자동 확인
- **24시간**에 한 번만 자동 확인 (Hive `lastUpdateCheckAt`)
- 새 버전이 있으면 다이얼로그: 나중에 / 이 버전 건너뛰기 / 다운로드
- **설정 → 앱 버전**에서 수동 확인 가능

### 관련 코드

```
lib/services/update_service.dart      # GitHub API, semver 비교
lib/providers/update_provider.dart    # Riverpod 상태, Hive 스킵·쿨다운
lib/widgets/dialogs/update_available_dialog.dart
```

### 릴리스 연동

`v*` 태그 push 시 [.github/workflows/release.yml](.github/workflows/release.yml)이 Windows/macOS zip을 GitHub Release에 올립니다. 앱은 해당 릴리스를 자동으로 조회합니다.

**요구 사항:** 저장소가 public이거나, API로 릴리스를 읽을 수 있어야 합니다. private 저장소는 별도 manifest 호스팅이 필요합니다.

## 프로젝트 구조

```
lib/
  models/       # .sub, .style 데이터 모델
  services/     # 파서, 파일 I/O, 스캔
  providers/    # Riverpod 상태
  windows/      # 조작·송출 UI
  widgets/      # 캔버스, 공통 위젯
```
