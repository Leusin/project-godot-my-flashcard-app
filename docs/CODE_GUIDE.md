# 코드 읽기 가이드

코드를 빠르게 파악하기 위한 가이드입니다.

아래 표는 "읽는 순서"만 제공하고, 파일별 상세 책임은 각 스크립트 맨 위 `//` 주석 참고.

## 두 덩어리

- **`src/core/`** — Godot을 전혀 모르는 순수 C#. 화면 없이 테스트로 검증된다.
- **`src/`** — 화면과 Godot을 아는 부분. core를 재료로 쓴다.

core는 바깥을 모르고, `StudyView`도 학습 규칙을 모른다. 규칙은 `Study`만 안다.

| # | 파일 | 흐름 단계 |
|---|---|---|
| 1 | `src/core/Card.cs` | 카드 한 장 = 질문 + 답 (데이터만) |
| 2 | `src/core/DeckParser.cs` | Markdown 텍스트 → 카드 목록 |
| 3 | `src/core/StudySession.cs` | 카드 큐. `Next()`로 한 장씩 소진 (판정 종류는 모름) |
| 4 | `src/core/Progress.cs` | Question별 WrongCount 기록 + JSON 직렬화 |
| 5 | `src/TallyMarks.cs` | 숫자를 작대기 그림으로 그리는 작은 뷰 (무엇을 세는지는 모름) |
| 6 | `src/card.tscn` · `src/CardView.cs` | 카드 한 장의 겉모습. 탭하면 앞뒤 전환, 틀린 횟수는 받아서 표시만 |
| 7 | `src/study.tscn` | 화면 골격 (상단바 + 카드 인스턴스 + 버튼, 시그널 연결). 카드는 `AspectRatioContainer`로 감싼다 |
| 8 | `src/StudyView.cs` | Study 화면 배치. 버튼 눌림을 시그널로 알림 (규칙 모름) |
| 9 | **`src/Study.cs`** | **지휘자: 덱 로드, 시그널 구독·해석, 진행도 저장** |
| 10 | `tests/TestRunner.cs` | 위 전부의 테스트 |

씬도 같은 원칙으로 나뉜다. `card.tscn`은 "카드 한 장이 어떻게 생겼나"만 알고, `study.tscn`은 그
카드를 화면 어디에 놓을지를 안다. 카드를 고칠 일이 생기면 `card.tscn` 하나만 열면 된다.

**레이아웃 수치의 출처는 씬이 아니라 `CardView`의 상수다.** 씬에는 값을 두지 않고 실행 시 코드가
넣는다. 값을 바꾸려면 상수만 고치면 되고, 씬이 덮어써져도 값은 살아남는다.

| 값 | 상수 | 넣는 곳 |
|---|---|---|
| 카드 가로:세로 비율 | `CardView.AspectRatio` | `StudyView._Ready()` → `AspectRatioContainer` |
| 글자 영역 최소 너비 | `CardView.MinTextWidth` | `CardView._Ready()` → 질문·답 라벨 |
| 뒷면 질문:답 세로 분할 | `CardView.QuestionStretch` · `AnswerStretch` | `CardView._Ready()` |
| 질문 폰트 (앞면/뒷면) | `CardView.QuestionFontFront` · `QuestionFontBack` | `CardView.SetAnswerVisible()` |
| 글자 정렬 (질문 가운데 / 답 왼쪽·위) | `CardView.QuestionHAlign` · `AnswerHAlign` · `QuestionVAlign` · `AnswerVAlign` | `CardView._Ready()` |
| 뒷면 질문 흐리기 | `CardView.QuestionTintBack` | `CardView.SetAnswerVisible()` |
| 뒷면 질문 표시 줄 수 (넘치면 …) | `CardView.QuestionLinesBack` | `CardView.SetAnswerVisible()` |

대신 에디터 미리보기에는 값이 반영되지 않는다. `study.tscn`의 카드가 1:1로 보이는 것, 그리고
라벨에 "최소 너비를 설정하라"는 경고가 남는 것은 정상이다 — 실행하면 코드가 채운다.

## 데이터 흐름 (카드 한 장을 넘길 때)

```
sample_deck.md
  → DeckParser.Parse()        : 텍스트를 Card 목록으로
  → StudySession(cards)       : 큐에 줄 세움
  → Study.ShowCurrent()       : 현재 카드를 꺼내
  → StudyView.ShowCard()      : 상단바를 갱신하고
  → CardView.ShowCard()       : 카드에 질문을 표시 (답은 숨김)
  → (사용자가 카드 탭)         : 앞뒤 전환. 다시 탭하면 질문으로 돌아온다
                                (판정 버튼은 답을 보기 전에도 항상 눌 수 있다)
  → (사용자가 Again 클릭)
  → StudyView가 시그널 발신    : "Again 눌림" — 사실
  → Study.OnAgain()           : WrongCount +1, 저장, 다음 카드로 — 해석
  → 다시 ShowCurrent()
```

## 실행

- 앱: 에디터에서 F5 (**반드시 .NET 에디터로 열 것** — `../tools/Godot_v4.7.1-stable_mono_win64/`, 바탕화면 바로가기 "Godot 4.7.1 (.NET)")
- 테스트·설정 반영은 Godot을 직접 부른다 (`_console.exe`라야 출력이 보인다):

```powershell
$godot = "..\tools\Godot_v4.7.1-stable_mono_win64\Godot_v4.7.1-stable_mono_win64_console.exe"

dotnet build
& $godot --headless --path . res://tests/tests.tscn                          # 테스트
& $godot --headless --path . --script res://src/debug/apply_project_settings.gd  # 설정 반영
```

## 파일 배치

```
src/core/     순수 로직 (Godot 의존 없음)
src/          씬과 Godot을 아는 코드
src/debug/    개발용 유틸 (apply_project_settings.gd — 프로젝트 설정의 출처)
tests/        TestRunner.cs + tests.tscn
assets/fonts/ Pretendard (한글 폰트)
docs/         이 문서들
sample_deck.md  v0.1용 하드코딩 덱
```

## 관련 문서

- [DESIGN](DESIGN.md) — 기획서. 데이터 규칙(카드 식별, 학습 규칙)의 기준
- [CONVENTIONS](CONVENTIONS.md) — 설계 원칙·코딩 컨벤션
- [ROADMAP](ROADMAP.md) — 버전별 목표
- [DEVLOG](DEVLOG.md) — 변경 이력과 결정 이유
