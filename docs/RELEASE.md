# 주원 송출 — 릴리즈

> `v*` 태그를 push하면 GitHub Actions가 Windows/macOS zip을 만들고 GitHub Release에 올린다.  
> 앱 업데이트 알림은 이 Release를 조회한다. ([README.md](../README.md) 「업데이트 알림」)

기준 워크플로: [`.github/workflows/release.yml`](../.github/workflows/release.yml)

---

## 한 줄 요약

기능 커밋 → `pubspec.yaml` 버전 올리기 → `Release vX.Y.Z` 커밋 → `vX.Y.Z` 태그 → push → Actions 「Release」 성공 확인.

---

## 체크리스트

### 1. 넣을 것과 빼기

- 릴리즈에 넣을 기능·수정만 `main`에 커밋한다.
- 개발용 `.sub` 수정(`dev/hymns/` 등)은 **넣지 않는다.** 이번 배포와 무관하면 커밋하지 말 것.

현재 버전 확인:

```bash
grep '^version:' pubspec.yaml
git tag -l --sort=-v:refname | head -5
```

형식은 `version: 1.1.2+7` — 앞이 사용자에게 보이는 버전, `+` 뒤는 빌드 번호.

### 2. 버전 올리기

`pubspec.yaml`만 바꾼다. Xcode `MARKETING_VERSION` 등은 CI가 `--build-name`으로 덮어쓰므로 손대지 않는다.

| 종류 | 언제 | 예시 (`1.1.2+7` 기준) |
|------|------|------------------------|
| patch | 버그·작은 UX | `1.1.3+8` |
| minor | 기능 묶음 | `1.2.0+8` |
| major | 호환 깨짐 | `2.0.0+8` |

`+` 빌드 번호는 **항상 1 올린다.**

### 3. 릴리즈 커밋

메시지 형식 (기존 커밋과 동일):

```
Release v1.1.3: 한 줄 한국어 요약.
```

본문에는 사용자 관점 변경을 2~3문장으로 적는다.

```bash
git add pubspec.yaml
# 이번 릴리즈에 포함할 다른 파일이 있으면 함께 add
git commit -m "$(cat <<'EOF'
Release v1.1.3: 한 줄 한국어 요약.

사용자에게 보이는 변경을 짧게 적는다.

EOF
)"
```

### 4. 태그

annotated 태그, 메시지 `주원 송출 vX.Y.Z`.

```bash
git tag -a v1.1.3 -m "주원 송출 v1.1.3"
```

태그는 `v` + semver. 이미 있는 태그는 재사용하지 않는다.

### 5. push (여기가 배포 트리거)

커밋만 push하면 릴리즈가 **안 만들어진다.** 태그를 같이 올려야 Actions가 돈다.

```bash
git push origin main
git push origin v1.1.3
```

### 6. 확인

1. Actions: [Release 워크플로](https://github.com/ha00h/joowon_subtitle/actions/workflows/release.yml)가 `vX.Y.Z`에서 **success**인지.
2. Release 페이지에 zip 두 개가 있는지.
   - `joowon-subtitle-X.Y.Z-macos.zip` (`JoowonCast.app`)
   - `joowon-subtitle-X.Y.Z-windows.zip`
3. Latest가 새 태그인지. 앱은 `GET /repos/ha00h/joowon_subtitle/releases/latest`로 비교한다.

```bash
gh run list --workflow=release.yml --limit 3
gh release view v1.1.3
```

빌드는 보통 5~10분. 수동으로 `gh release create` 하지 않는다. 워크플로가 `주원 송출 vX.Y.Z` 이름으로 만들고 노트는 자동 생성한다.

---

## 버전·태그·CI가 맞물리는 방식

| 항목 | 역할 |
|------|------|
| `pubspec.yaml` `version:` | 로컬 실행·패키지 정보의 기준 |
| 태그 `v1.1.3` | Release 워크플로 트리거. 태그에서 `v`를 뺀 값이 `--build-name` |
| CI `--build-number=1` | zip 빌드에만 사용. pubspec의 `+N`과 달라도 됨 |
| GitHub Release asset | 앱 업데이트 다이얼로그의 다운로드 URL |

워크플로 Flutter 버전은 `release.yml`의 `flutter-version`(현재 `3.44.2`)과 맞춘다.

---

## 하지 말 것

- 커밋만 push하고 태그는 안 올리기
- `v1.1.3`처럼 이미 있는 태그를 고쳐서 재push
- draft / prerelease로 Release 만들기 (`latest` API가 그 버전을 안 잡을 수 있음)
- `main` push로 뜨는 **Test** / **Build Windows** 실패를 릴리즈 실패로 착각하기  
  배포 성패는 **Release** 워크플로만 보면 된다. (이 두 잡은 과거에도 자주 실패했다.)

---

## 실패했을 때

| 증상 | 확인 |
|------|------|
| Actions에 Release 런이 없음 | 태그가 remote에 있는지 `git ls-remote --tags origin 'v*'` |
| macOS zip 없음 | `JoowonCast.app` 경로, `ditto` 단계 로그 |
| Windows zip 없음 | `build/windows/x64/runner/Release` 로그 |
| 앱이 새 버전을 모름 | Release가 Latest인지, 태그에서 `v` 뺀 값이 semver인지 |

실패한 태그를 고치려면 **새 patch 버전**으로 다시 릴리즈하는 편이 안전하다. 같은 태그를 지우고 다시 올리는 것은 피할 것.

---

## 최근 예시 (v1.1.2)

1. 기능 커밋: 앱 시작 시 송출 창을 열지 않음
2. `pubspec.yaml`: `1.1.1+6` → `1.1.2+7`
3. 커밋: `Release v1.1.2: 앱 시작 시 송출을 Off로 시작.`
4. 태그: `v1.1.2` / `주원 송출 v1.1.2`
5. `main` + 태그 push → Release 워크플로 success
6. https://github.com/ha00h/joowon_subtitle/releases/tag/v1.1.2
