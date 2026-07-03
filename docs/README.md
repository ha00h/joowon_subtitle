# Joowon Subtitle — 문서 목록

> 교회 찬양 자막기 프로젝트 개발 문서  
> MVP v0.6 · Flutter Desktop

---

## 문서 구성

| 문서 | 설명 | 대상 |
|------|------|------|
| [MVP.md](./MVP.md) | 기능·범위·데이터 형식 **명세** (기준 문서) | 전원 |
| [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md) | **개발 계획** — Phase, 마일스톤, 작업 분해 | 개발 |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | **기술 아키텍처** — 모듈, 상태, 윈도우 | 개발 |
| [SETUP.md](./SETUP.md) | **개발 환경** — Mac 셋업, Windows CI 빌드 | 개발 |
| [VERIFICATION.md](./VERIFICATION.md) | **검증 방법** — 단위/통합/수동/수용 테스트 | 개발·QA |

---

## 읽는 순서 (권장)

```
1. MVP.md           → 무엇을 만드는지
2. ARCHITECTURE.md  → 어떻게 나눌지
3. SETUP.md         → 환경 준비
4. DEVELOPMENT_PLAN.md → 무엇부터 할지
5. VERIFICATION.md  → 완료 기준·테스트
```

---

## 문서 간 관계

```
MVP.md (무엇)
    ├── DEVELOPMENT_PLAN.md (일정·작업)
    ├── ARCHITECTURE.md (구조)
    ├── SETUP.md (환경)
    └── VERIFICATION.md (검증)
```

명세 변경 시 **MVP.md를 먼저** 수정하고, 영향 받는 문서를 갱신한다.
