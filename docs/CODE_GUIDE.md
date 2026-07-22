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
| 2 | `src/core/DeckParser.cs` · `DeckWriter.cs` | Markdown ↔ 카드 목록 (읽기/쓰기 짝, 왕복 안정) |
| 3 | `src/core/StudySession.cs` | 카드 큐. `Next()`로 한 장씩 소진 (판정 종류는 모름) |
| 4 | `src/core/Progress.cs` | Question별 WrongCount 기록 + JSON. `Rename()` 질문 바뀌면 이사, `Remove()` 카드 지우면 정리 |
| 5 | `src/core/DeckNaming.cs` · `DeckInfo.cs` · `CardRow.cs` · `AppSettings.cs` | 덱 이름 규칙, 덱/카드 목록 한 줄의 사실, 마지막 사용 덱 |
| 6 | `src/DeckStorage.cs` | `user://`의 덱·진행도·설정 파일 위치와 읽고 쓰기 (파싱은 모름) |
| 7 | `screens/study/TallyMarks.cs` | 숫자를 작대기 그림으로 그리는 작은 뷰 (무엇을 세는지는 모름) |
| 8 | `screens/study/card.tscn` · `CardView.cs` | 카드 한 장의 겉모습. 탭하면 앞뒤 전환, 틀린 횟수는 받아서 표시만 |
| 9 | `screens/study/study.tscn` | 화면 골격 (상단바 + 카드 인스턴스 + 버튼, 시그널 연결). 카드는 `AspectRatioContainer`로 감싼다 |
| 10 | `screens/study/StudyView.cs` | Study 화면 배치. 버튼 눌림을 시그널로 알림 (규칙 모름) |
| 11 | **`screens/study/Study.cs`** | **세션 관리자: 받은 덱 로드, 시그널 구독·해석, 진행도 저장** |
| 12 | `screens/deck_list/deck_list.tscn` · `DeckListView.cs` | 덱 목록 배치. 고른 덱·가져올 파일을 시그널로 알림 |
| 13 | `screens/card_list/card_list.tscn` · `CardListView.cs` | 한 덱의 카드 목록(질문 + 틀린 횟수). 고른 카드·뒤로 가기를 시그널 |
| 14 | `screens/card_editor/card_editor.tscn` · `CardEditorView.cs` | 카드 질문/답 편집. 나갈 때 입력값·삭제를 사실로 알림 (저장·삭제 해석은 App) |
| 15 | **`src/app.tscn` · `src/App.cs`** | **진입점: 화면 전환, Import, 마지막 사용 덱 기억, 편집 저장·진행도 이사 해석** |
| 16 | `tests/TestRunner.cs` | 위 전부의 테스트 |

`Study`는 어떤 덱을 열지 스스로 정하지 않는다. `App`이 `StartDeck(deckFile)`로 지정하고, `Study`는
화면을 떠나거나(`ExitRequested`) 편집으로 가고 싶다는(`EditRequested`) 사실만 위로 알린다.

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

## 화면 흐름 (누가 누구를 아는가)

```
              App  ── 마지막 덱 기억, 화면 전환, Import, 편집 저장·진행도 이사
   ┌──────────┼──────────┬──────────┐    ↑ 위로는 "사실"만 올라간다
   ↓          ↓          ↓          ↓
DeckListView Study    CardListView CardEditorView
 "고른 덱:X" "나가고"   "고른 카드:i" "다 됐다(질문,답)"
 "가져와"    "편집으로" "뒤로"
```

App은 지금 보는 덱(`_currentDeck`)을 들고, Study·카드 목록·편집기가 같은 덱을 가리키게 한다. Study ✏(`EditRequested`) → 카드 목록, 카드 목록에서 카드 탭(`CardChosen`) → 편집기, 편집기 ←(`EditingDone`) → App이 **바뀐 경우에만** md 재저장 + 질문 바뀌면 `Progress.Rename`으로 진행도 이사(모델 A) → 카드 목록 복귀. 편집기는 "저장하라"를 모른다 — 입력값이라는 사실만 올린다.

폴더도 같은 모양이다: 앱은 `src/` 바로 아래, 화면은 `src/screens/<화면>/`에 씬과 스크립트가 한 벌로 들어간다.

- **아래는 위를 모른다.** `DeckListView`는 App도 Study도 모르고, 어떤 덱을 골랐다는 사실만 시그널로 올린다. `Study`도 다음 화면이 무엇인지 모르고 `ExitRequested`·`EditRequested`만 올린다.
- **그래서 화면을 추가할 때 고칠 곳은 App 하나다.** 새 화면은 자기 시그널만 내면 된다.
- 화면끼리는 서로를 모른다. 목록 → Study 전환은 App의 해석이다.

## 앱 저장소

경로 상수와 파일 IO는 전부 `DeckStorage`에 모여 있다.

```
<덱 폴더>/<덱이름>.md            덱(원본 md). 목록에 나오는 것은 이 폴더의 파일뿐
user://progress/<덱이름>.json   진행도. 덱마다 따로 (카드 식별자가 Question이라 덱 간 충돌을 막는다)
user://settings.json            마지막 사용 덱 + 덱 폴더 경로
```

**덱 폴더만 바꿀 수 있고, 진행도·설정은 `user://` 고정이다.** 진행도는 앱이 만드는 파생 데이터라 원본과 함께 옮길 이유가 없고, 파일 이름으로 키를 잡으니 덱이 어디 있든 짝이 맞는다.

- 기본 덱 폴더는 `user://decks`. 사용자가 덱 목록에서 폴더를 바꾸면 그 경로(절대 경로 가능)를 `settings.DeckDir`에 저장하고, 시작 시 `DeckStorage.SetDecksDir`로 되살린다.
- **동기화는 앱이 모른다** — 이 폴더를 Drive 동기화 폴더로 두면 기기 간 동기화는 OS가 한다(해석 B). 앱은 로컬 파일만 읽고 쓴다.
- 그래서 예시 덱(`res://sample_deck.md`)은 **기본 폴더가 비었을 때만** 복사한다. 사용자가 지정한 폴더에는 앱이 파일을 끼워넣지 않는다.

## 데이터 흐름 (카드 한 장을 넘길 때)

```
user://decks/<덱>.md
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

- 앱: 에디터에서 F5 (진입 씬은 `src/app.tscn`, **반드시 .NET 에디터로 열 것** — `../tools/Godot_v4.7.1-stable_mono_win64/`, 바탕화면 바로가기 "Godot 4.7.1 (.NET)")
- 테스트·설정 반영은 Godot을 직접 부른다 (`_console.exe`라야 출력이 보인다):

```powershell
$godot = "..\tools\Godot_v4.7.1-stable_mono_win64\Godot_v4.7.1-stable_mono_win64_console.exe"

dotnet build
& $godot --headless --path . res://tests/tests.tscn                          # 테스트
& $godot --headless --path . --script res://src/debug/apply_project_settings.gd  # 설정 반영
```

## 파일 배치

```
src/          앱 전체 (app.tscn · App.cs · DeckStorage.cs)
src/screens/  화면 한 벌씩 (deck_list · study · card_list · card_editor — 씬 + 스크립트를 같은 폴더에)
src/core/     순수 로직 (Godot 의존 없음)
src/debug/    개발용 유틸 (apply_project_settings.gd — 프로젝트 설정의 출처)
tests/        TestRunner.cs + tests.tscn
assets/fonts/ Pretendard (한글 폰트)
docs/         이 문서들
sample_deck.md  첫 실행 시 앱 저장소로 복사되는 예시 덱
```

## 관련 문서

- [DESIGN](DESIGN.md) — 기획서. 데이터 규칙(카드 식별, 학습 규칙)의 기준
- [CONVENTIONS](CONVENTIONS.md) — 설계 원칙·코딩 컨벤션
- [ROADMAP](ROADMAP.md) — 버전별 목표
- [DEVLOG](DEVLOG.md) — 변경 이력과 결정 이유
