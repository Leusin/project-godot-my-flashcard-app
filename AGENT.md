# MyFlashCard App

Markdown으로 카드를 작성하고 Reigns 스타일 스와이프로 복습하는 플래시카드 앱 (Godot 4 .NET, C#). 기획은 [docs/DESIGN.md](docs/DESIGN.md), 이정표는 [docs/ROADMAP.md](docs/ROADMAP.md) 참고.

## 설계 규칙

[docs/CONVENTIONS.md](docs/CONVENTIONS.md)가 규칙의 기준이다. 특히:

- **의존 방향**: 하위(카드·파서·입력)는 상위(세션 규칙·저장 관리)를 호출하지 않는다. 상위가 하위를 구독한다.
- **사실 vs 해석**: 하위는 사실(스와이프 방향, 파싱 결과)만 노출하고, Again/Good 처리나 진행도 갱신 같은 해석은 세션 관리자가 한다.
- **뷰는 읽기만**: 카드 UI·목록 UI는 상태를 읽어 표시만 한다.
- 새 시스템을 시작할 때는 패턴 이름만으로 구조를 잡지 말 것. **참조 가능/불가 대상과 의존 방향을 먼저 확인**하고 시작한다.

## 협업 규칙

- 조작감에 영향 주는 값(스와이프 임계값, 애니메이션 시간)은 구조 개선이 목적이라도 **사람의 사용 확인 전에는 확정하지 않는다.**
- 검증 분담: AI는 헤드리스 실행(빌드·테스트, 파서/런타임 에러 확인)을 맡고, 화면에 보이는 것의 최종 판정은 사람이 한다.
- 아트는 시안부터 사람이 판정한다.
- 기능 묶음이 끝나면 정리 리뷰 → MINOR 버전 올리고 `git tag vX.Y.Z` → 사이클이 끝나면 회고(docs/MEMORY.md).

## 문서 체계

- [docs/DESIGN.md](docs/DESIGN.md) — 기획서. 데이터 규칙(카드 식별, 학습 규칙, Import)의 기준.
- [docs/ROADMAP.md](docs/ROADMAP.md) — 버전별 목표와 완료/예정 항목.
- [docs/DEVLOG.md](docs/DEVLOG.md) — 결정·교훈을 그날 기록. 세션 시작 시 최근 엔트리를 읽으면 맥락이 잡힌다.
- [docs/MEMORY.md](docs/MEMORY.md) — 프로젝트 목표·가설·회고.
- ARCHITECTURE / TESTING 문서는 코드가 생기면 작성한다.

## 테스트

테스트 하네스는 코드가 생기면 구성한다. 순수 로직(Markdown 파서, 세션 큐, 진행도 저장)이 단위 테스트 1순위 대상. Godot 씬 없이 돌 수 있게 일반 C# 클래스로 분리해 둘 것.
