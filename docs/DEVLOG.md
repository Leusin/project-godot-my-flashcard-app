# DEVLOG

결정과 교훈을 그날 기록한다. 세션이 끊겨도 이 문서만 읽으면 이어서 작업할 수 있게 쓴다.

## 2026-07-21 v0.1 최소 루프 구현

- Godot 4.7.1 .NET 에디션을 `../tools/`에 설치 (Steam 버전은 C# 미지원 — 이 프로젝트는 반드시 .NET 에디터로 열 것. 표준 빌드로 열면 씬이 안 열리고 project.godot의 "C#" feature가 지워진다).
- 순수 로직(src/core: Card, DeckParser, StudySession, Progress)을 Node 없이 분리 → 테스트 29개가 헤드리스로 통과. 씬 배선도 tests의 스모크 테스트가 검증 (버튼 시그널로 세션 한 바퀴 + 재실행 시 WrongCount 로드).
- 뷰/세션 분리: StudyView는 표시 + 시그널만, Main이 구독해 해석 (CONVENTIONS 의존 방향).
- 아이콘을 플래시카드 테마(카드 2장 겹침)로 교체. `#` 기호는 시안 검토에서 제거 — 카드만 남기는 게 깔끔.
- 남은 것: 실사용 검증(8단계) 후 v0.1 태그.

## 2026-07-21 기획 다듬기

- 기획서 직접 수정: Deck List의 `:` 연결을 Deck Menu로 통일(모순 해소), Card List에 WrongCount 표시, Study 순서 옵션(Shuffle/Sequential) 추가, 비목표를 "SRS 전체"로 명확화.
- 카드 상태(NEW/LEARNING/MASTERED)는 **수동 설정 표시용 라벨**로 확정. 자동 전이와 MASTERED Study 제외는 향후 아이디어로.
- WrongCount는 Again 시 자동 증가 + Card Editor에서 수동 수정 가능.
- 로드맵 반영: 상태 라벨·WrongCount 수정은 v0.3(편집), Study 순서 토글은 보류(v0.1은 고정 순서).

## 2026-07-20 프로젝트 세팅

- 기획서 리뷰를 거쳐 세 가지 데이터 규칙 확정 (DESIGN.md "데이터 규칙" 섹션):
  - 카드 식별자 = Question 텍스트. 질문 수정 시 진행도 초기화를 스펙으로 수용.
  - 학습 규칙: Again(WrongCount+1, 세션 큐 뒤로) / Good(세션 완료) / Pass(세션 건너뛰기).
  - Import = md를 앱 내부 저장소로 복사, 이후 앱 저장소가 원본. Export로 다시 꺼냄.
- 로드맵을 v0.1(최소 루프) → v0.2(여러 덱) → v0.3(편집) → v1.0(스와이프 + Android)으로 확정. 기획서의 나머지 기능(Pass/Previous, 카드 상태, 드래그 정렬 등)은 보류로 분리.
- 운영 체계는 mini-rhythm-game에서 계승: 문서 체계(CONVENTIONS/DEVLOG/ROADMAP/MEMORY + CLAUDE.md), 보편 설계 원칙. 이 프로젝트는 C#이므로 테스트 하네스는 코드 시작 시 새로 구성.
- 알려진 리스크: Godot 4 .NET의 Android export. v0.1 직후 빈 프로젝트로 실기기 검증 예정.
- Godot 프로젝트 파일은 아직 없음. 다음 작업 = v0.1 첫 항목(프로젝트 생성).
