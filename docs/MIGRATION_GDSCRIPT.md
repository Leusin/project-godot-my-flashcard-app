# C# → GDScript 마이그레이션 기록

> 상태: **완료 (2026-08-13)**. 아래 내용은 전환 과정과 검증 기준을 보존한 역사 문서다.

## 1. 목적

이 작업은 현재 C# 구현을 GDScript로 단순 번역하는 작업이 아니다. 다음 두 목표를 함께 달성한다.

1. 기존 앱의 동작과 사용자 데이터를 보존하면서 C#/.NET 의존성을 제거한다.
2. 구현 과정을 통해 Godot의 구조와 주요 사용법을 직접 익힌다.

완료 상태는 다음과 같다.

- 일반 Godot 빌드에서 앱과 테스트가 실행된다.
- 기존 Markdown 덱, 진행도 JSON, 설정 JSON을 그대로 읽는다.
- 현재 `master`의 기능과 화면 흐름이 유지된다.
- 모든 `.cs`, `.csproj`, `.sln` 및 `[dotnet]` 의존성을 제거할 수 있다.
- 각 계층이 왜 분리되어 있는지 설명하고, 작은 기능을 스스로 추가할 수 있다.

## 2. 현재 기준선

문서의 v0.3 체크리스트만 기준으로 삼지 않는다. 마이그레이션 기준은 **작업 시작 시점의 `master` 코드와 테스트**다.

현재 보존해야 할 기능은 다음과 같다.

- Markdown 파싱 및 재작성
- 덱 생성, 가져오기, 내보내기, 이름 변경, 복제, 삭제
- 덱 저장 폴더 변경과 마지막 덱 기억
- 덱 허브와 Sequential/Shuffle 선택
- 카드 목록과 카드 생성, 편집, 복제, 삭제
- 질문 변경 시 진행도 이전
- WrongCount와 NEW/LEARNING/MASTERED 상태
- Again/Good 학습과 완료 후 재시작
- 학습 중 현재 카드 편집 및 삭제
- 카드 앞·뒷면 전환
- 카드 기울기, 퇴장, 다음 카드 안착 모션
- 공통 테마와 화면별 메뉴·다이얼로그

현재 C# 테스트에는 184개의 `Check` 호출이 있다. 이 숫자 자체보다 각 검증 항목을 GDScript 쪽에서 다시 통과시키는 것이 중요하다.

## 3. 마이그레이션 원칙

### 3.1 동작 보존과 구조 개선을 분리한다

마이그레이션 중에는 기존 동작을 의도적으로 바꾸지 않는다. 다음 개선은 GDScript 전환이 끝난 뒤 별도 작업으로 다룬다.

- 카드 영구 ID 도입
- 진행도 형식 변경
- App 책임 분리
- 코드 기반 Theme를 `.tres`로 이전
- 새로운 학습 규칙이나 화면 추가
- 애니메이션 값 조정

버그처럼 보여도 기존 설계에서 수용한 동작일 수 있다. 특히 중복 질문이 진행도를 공유하는 것은 현재 데이터 모델의 일부다.

### 3.2 아래 계층부터 옮긴다

의존 방향과 같은 순서로 작업한다.

```text
core → storage → 작은 view → 복합 view → Study → App → .NET 제거
```

App부터 옮기면 아직 없는 GDScript 하위 타입을 임시 코드로 메워야 한다. 순수 로직부터 옮기면 매 단계마다 작게 검증할 수 있다.

### 3.3 한 기능에는 한 구현만 사용한다

C#과 GDScript 구현을 비교용으로 함께 보관할 수는 있지만, 실행 중 같은 책임을 동시에 맡기지 않는다.

예를 들어 `DeckParser.cs`와 `deck_parser.gd`가 함께 있더라도 실제 GDScript 테스트는 GDScript 파서만 호출한다. 두 구현의 결과를 섞으면 어느 쪽의 오류인지 판단하기 어려워진다.

### 3.4 데이터 파일을 먼저 보호한다

기존 형식을 그대로 유지한다.

```text
<deck-dir>/<deck-name>.md
user://progress/<deck-name>.json
user://settings.json
```

특히 진행도는 두 형식을 모두 읽어야 한다.

```json
{"질문": 3}
```

```json
{
  "질문": {
	"wrong": 3,
	"status": "LEARNING"
  }
}
```

GDScript 버전이 만든 파일을 다시 C# 버전도 읽을 수 있어야 한다. 완전 전환 전까지는 이 양방향 호환을 회귀 검증으로 사용한다.

### 3.5 씬은 가능한 한 재사용한다

`.tscn`의 노드 구조, 이름, Unique Name, 레이아웃은 유지하고 붙어 있는 스크립트만 교체한다. 화면 구조 변경과 언어 전환을 동시에 하지 않는다.

### 3.6 각 단계는 실행 가능한 상태로 끝낸다

한 번에 모든 `.cs` 파일을 제거하지 않는다. 단계가 끝날 때마다 다음을 만족해야 한다.

- 파서 또는 씬 로드 오류가 없다.
- 해당 단계의 자동 검증이 통과한다.
- 관련 화면을 직접 조작할 수 있다.
- 무엇을 배웠는지 짧게 기록한다.

## 4. 목표 구조

기존 책임과 폴더 모양을 최대한 유지한다.

```text
src/
├── app.gd
├── app.tscn
├── app_theme.gd
├── storage/
│   └── deck_storage.gd
├── core/
│   ├── flash_card.gd
│   ├── card_status.gd
│   ├── deck_info.gd
│   ├── card_row.gd
│   ├── app_settings.gd
│   ├── deck_naming.gd
│   ├── deck_parser.gd
│   ├── deck_writer.gd
│   ├── deck_ordering.gd
│   ├── progress.gd
│   └── study_session.gd
├── screens/
│   └── 기존 화면별 폴더
└── debug/
	└── apply_project_settings.gd

tests/
├── test_runner.gd
└── tests.tscn
```

`DeckStorage`를 `storage/`로 옮기는 것은 선택 사항이다. 경로 이동 때문에 작업량이 늘어난다면 전환이 끝날 때까지 `src/deck_storage.gd`에 두어도 된다.

## 5. C#과 GDScript 대응 규칙

| C# | GDScript 방향 |
| --- | --- |
| `record Card` | `class_name FlashCard extends RefCounted` |
| `enum CardStatus` | 전용 스크립트의 `enum Value` 또는 공유 enum |
| static utility class | `class_name` + `static func` |
| `[Signal] delegate` | `signal signal_name(args)` |
| C# event 구독 | `node.signal_name.connect(callable)` |
| `GetNode<T>("%Name")` | `@onready var name: Type = %Name` |
| nullable reference | `Variant`/nullable 객체 + 명시적 `null` 검사 |
| `List<T>` | 타입 지정 `Array[T]` |
| `Dictionary<string, T>` | `Dictionary[String, T]` 또는 런타임 검증 |
| `System.Text.Json` | `JSON.parse_string`, `JSON.stringify` |
| `using`으로 파일 닫기 | `FileAccess` 참조 해제 및 오류 검사 |
| C# property | 일반 변수, getter/setter 또는 계산 함수 |
| `Random` 주입 | 테스트 가능한 RNG 인자 또는 seed 설정 |
| `Task`/event callback | signal, `await signal`, Callable |

모든 GDScript 파일에는 가능한 범위에서 정적 타입을 적는다. 동적 언어의 편리함보다 오류를 일찍 발견하는 것을 우선한다.

```gdscript
func parse(text: String) -> Array[FlashCard]:
	var cards: Array[FlashCard] = []
	return cards
```

## 6. 학습 방식

각 단계는 다음 순환으로 진행한다.

1. **읽기**: 기존 C# 파일의 책임 주석과 테스트를 읽는다.
2. **예측**: 입력, 출력, 의존 대상을 코드 보기 전에 짧게 적는다.
3. **작은 구현**: 한 클래스 또는 한 흐름만 GDScript로 옮긴다.
4. **자동 검증**: 정상·경계·오류 입력을 테스트한다.
5. **에디터 확인**: Remote Scene Tree, Signals, Inspector로 실제 상태를 본다.
6. **설명**: “왜 이 노드가 이 책임을 갖는가”를 자기 말로 기록한다.
7. **작은 변형**: 결과를 망가뜨리지 않는 미니 실습을 한 번 한다.

단순히 완성 코드를 복사하는 것보다, 각 단계의 첫 번째 작은 구현은 직접 작성하는 편이 학습 목표에 맞다. 막히는 부분은 기존 C# 코드와 테스트를 정답지로 사용한다.

각 단계 완료 시 `docs/DEVLOG.md`에 다음 형식으로 5줄 이내 기록한다.

```text
- 옮긴 책임:
- 새로 이해한 Godot 개념:
- 가장 헷갈린 점:
- 자동 검증:
- 직접 확인한 화면:
```

## 7. 단계별 계획

### Phase 0 — 실행 환경과 기준선 고정

#### 구현 작업

- 일반 Godot 4 프로젝트를 실행할 수 있는 환경을 준비한다.
- 기존 C# 버전을 실행할 수 있는 환경은 완전 전환까지 비교 기준으로 보존한다.
- 작업 시작 커밋과 Godot 버전을 기록한다.
- 주요 화면을 캡처한다.
- 대표 덱과 진행도 fixture를 준비한다.
- 테스트 항목을 core, storage, scene, app 흐름으로 분류한다.

대표 fixture에는 최소한 다음 사례를 넣는다.

- 빈 덱
- 한 장과 여러 장의 덱
- 여러 줄 답
- 빈 답
- 중복 질문
- 잘못된 진행도 JSON
- 옛 진행도 형식
- 현재 진행도 형식

#### 학습 목표

- 프로젝트 매니저, 에디터, 실행 씬의 관계
- `res://`와 `user://`의 차이
- Main Scene과 Project Settings
- Scene dock, Inspector, Output, Debugger 사용법

#### 미니 실습

- 빈 테스트 씬을 만들고 `print()`가 출력되는지 확인한다.
- `ProjectSettings.globalize_path("user://")` 결과를 확인한다.

#### 완료 기준

- C# 기준선의 기능 목록과 테스트 결과가 기록돼 있다.
- GDScript 테스트 씬이 일반 Godot에서 실행된다.
- 실제 사용자 데이터가 아닌 복사본으로 호환성 검증을 시작할 수 있다.

### Phase 1 — 데이터 모델과 가장 작은 순수 로직

#### 대상

- `Card.cs` → `flash_card.gd`
- `CardStatus.cs` → `card_status.gd`
- `DeckInfo.cs` → `deck_info.gd`
- `CardRow.cs` → `card_row.gd`
- `DeckNaming.cs` → `deck_naming.gd`

#### 구현 작업

- 데이터 객체는 `RefCounted`로 만든다.
- 화면에 노출할 이름과 파일 이름을 구분한다.
- 확장자 판정과 중복 이름 생성 규칙을 그대로 옮긴다.
- 대소문자를 무시하는 충돌 규칙을 테스트한다.

#### 학습 목표

- `Object`, `RefCounted`, `Node`, `Resource`의 차이
- `class_name`, `extends`, `_init`
- 타입 지정 변수와 배열
- static 함수와 인스턴스 함수의 차이

#### 미니 실습

- 같은 데이터 객체를 두 변수가 참조할 때 변경이 어떻게 보이는지 확인한다.
- `Node`로 만들 필요가 없는 이유를 설명한다.

#### 완료 기준

- 이름 규칙 테스트가 GDScript에서 통과한다.
- 데이터 객체가 Scene Tree 없이 생성되고 해제된다.

### Phase 2 — Markdown 파서와 writer

#### 대상

- `DeckParser.cs` → `deck_parser.gd`
- `DeckWriter.cs` → `deck_writer.gd`

#### 구현 작업

- `# `로 시작하는 줄을 질문으로 해석한다.
- 첫 질문 이전 내용, 빈 질문, CRLF, 빈 답을 기존과 동일하게 처리한다.
- `parse(to_markdown(cards)) == cards` 왕복 테스트를 만든다.
- 답 안의 `# ` 시작 줄이 새 카드로 해석되는 현재 한계를 문서화한다.

#### 학습 목표

- GDScript 문자열, `split`, `strip_edges`, `trim_suffix`
- typed array 반복
- 순수 함수와 부수 효과
- 테스트 실패를 최소 입력으로 줄이는 방법

#### 미니 실습

- 파서를 일부러 한 번 깨뜨리고 어떤 테스트가 잡는지 확인한 뒤 복구한다.

#### 완료 기준

- 기존 parser/writer 테스트와 대표 fixture가 통과한다.
- 파일 IO 없이 문자열만으로 검증된다.

### Phase 3 — 학습 큐, 순서, 진행도와 설정

#### 대상

- `StudySession.cs`
- `DeckOrdering.cs`
- `Progress.cs`
- `AppSettings.cs`

#### 구현 작업

- Sequential은 원본 배열을 변경하지 않고 복사한다.
- Shuffle은 재현 가능한 테스트 경로를 둔다.
- 현재 카드 교체, 다음 카드, 완료, 남은 수를 옮긴다.
- 진행도의 기본값, 증가, 수정, rename, merge, remove를 옮긴다.
- 잘못된 JSON과 두 가지 진행도 형식을 모두 처리한다.
- GDScript가 쓴 JSON을 C# 버전이 읽는지 비교한다.

#### 학습 목표

- 참조 복사와 `duplicate()`
- `RandomNumberGenerator`와 seed
- Dictionary 값의 런타임 타입 검사
- JSON 파싱 실패 처리
- 도메인 규칙과 저장 형식의 분리

#### 미니 실습

- 같은 seed로 Shuffle 결과가 같은지 확인한다.
- 손상된 JSON을 넣고 앱이 빈 기본값으로 회복하는지 본다.

#### 완료 기준

- `src/core/`에 해당하는 모든 순수 로직 테스트가 통과한다.
- core 스크립트가 `FileAccess`, 화면 노드 또는 autoload를 참조하지 않는다.

### Phase 4 — 파일 저장소

#### 대상

- `DeckStorage.cs` → `deck_storage.gd`

#### 구현 작업

- 기본 덱 폴더와 커스텀 절대 경로를 처리한다.
- list/read/write/import/export를 옮긴다.
- rename/duplicate/delete 시 진행도 파일도 함께 처리한다.
- 기본 폴더가 비었을 때만 샘플 덱을 넣는다.
- 모든 실패 경로에서 Godot의 `Error` 또는 `null`을 확인한다.

`DeckStorage`는 처음에는 static 함수 모음으로 유지한다. autoload는 전역 접근이 실제로 필요하다는 근거가 생긴 뒤 검토한다.

#### 학습 목표

- `FileAccess`와 `DirAccess`
- `res://`, `user://`, 절대 경로
- Godot의 `Error` 값
- autoload의 장점과 전역 상태 비용
- 파일 대화상자 경로와 실제 저장 경로의 차이

#### 미니 실습

- 임시 전용 폴더를 덱 폴더로 지정하고 CRUD 전체를 수행한다.
- 존재하지 않는 파일을 읽을 때 반환값과 에러를 확인한다.

#### 완료 기준

- 테스트 전용 파일만 만들고 정리하는 저장소 테스트가 통과한다.
- 기존 C# 버전의 fixture와 GDScript 버전의 읽기 결과가 같다.
- 실제 사용자 덱을 수정하지 않는다.

### Phase 5 — 작은 씬과 재사용 컴포넌트

#### 권장 순서

1. `TallyMarks`
2. `CardView`
3. `DeckTile`
4. `CardRowView`
5. `DeckHomeView`
6. `CardEditorView`

#### 구현 작업

- 기존 노드 이름과 Unique Name을 유지한다.
- `@onready` 변수에 구체적인 노드 타입을 지정한다.
- C# signal을 GDScript signal로 옮긴다.
- `queue_redraw()`, `_draw()`, `gui_input`을 옮긴다.
- 한 씬씩 `.cs` 참조를 `.gd`로 바꾸고 즉시 로드 테스트한다.

#### 학습 목표

- Scene과 Node의 관계
- PackedScene과 인스턴스 생성
- Owner와 Scene Tree
- `@onready`, `%UniqueName`, `$NodePath`
- signal 선언, 연결, 발신
- `_ready`, `_process`, `_draw`, `_gui_input`
- Control의 anchor, offset, container sizing

#### 미니 실습

- 에디터의 Node 탭에서 signal을 찾아 연결 상태를 확인한다.
- Remote Scene Tree에서 런타임 생성된 타일과 행을 찾는다.
- Tally의 count를 런타임에 바꾸고 redraw 시점을 확인한다.

#### 완료 기준

- 각 씬을 단독 실행하거나 테스트 씬에서 인스턴스화할 수 있다.
- signal이 한 번만 발신된다.
- 카드 앞·뒷면과 긴 텍스트 스크롤이 기존처럼 동작한다.

### Phase 6 — 목록 화면과 동적 UI

#### 대상

- `DeckListView.cs`
- `CardListView.cs`

#### 구현 작업

- PackedScene preload와 동적 행/타일 생성을 옮긴다.
- 기존 자식 노드를 안전하게 비우는 코드를 만든다.
- 메뉴 대상 index/deck 상태를 유지한다.
- PopupMenu ID와 rename/delete 확인 흐름을 옮긴다.
- FileDialog의 파일·폴더 선택 signal을 옮긴다.

#### 학습 목표

- `preload`와 `load`의 차이
- `instantiate`, `add_child`, `queue_free`
- Callable과 signal argument binding
- PopupMenu, ConfirmationDialog, FileDialog
- 프레임 끝에 삭제되는 노드의 생명주기

#### 미니 실습

- 타일을 여러 번 다시 그려 signal 중복 연결이나 유령 노드가 없는지 Remote Tree에서 확인한다.
- 메뉴 클릭 시 대상 덱/index가 정확한지 출력으로 추적한다.

#### 완료 기준

- 빈 목록, 한 항목, 여러 항목이 정상 표시된다.
- 모든 메뉴 signal이 올바른 대상 정보를 전달한다.
- 다시 표시할 때 항목이 중복되지 않는다.

### Phase 7 — 테마

#### 대상

- `AppTheme.cs` → `app_theme.gd`

#### 구현 작업

- 팔레트, 폰트, 간격, radius 토큰을 그대로 옮긴다.
- Theme type variation을 유지한다.
- StyleBoxFlat, StyleBoxLine, StyleBoxEmpty 생성 코드를 옮긴다.
- 기존 화면 캡처와 나란히 비교한다.

1차 마이그레이션에서는 코드 기반 Theme를 유지한다. `.tres` 전환은 완료 후 별도 학습 과제로 둔다.

#### 학습 목표

- Theme 상속과 override 우선순위
- theme type variation
- StyleBox와 폰트 리소스
- 코드 생성 리소스와 `.tres` 리소스의 차이

#### 미니 실습

- 한 버튼에만 type variation을 바꿔 상속 결과를 확인한 뒤 되돌린다.
- Inspector의 theme override가 전역 Theme보다 우선하는지 확인한다.

#### 완료 기준

- 주요 화면의 색, 글자 크기, 간격, 버튼 상태가 기존과 눈에 띄게 다르지 않다.
- Focus, hover, pressed, disabled 상태를 직접 확인한다.

### Phase 8 — Study와 애니메이션

#### 대상

- `StudyView.cs`
- `Study.cs`

#### 구현 작업

- View는 Again/Good/Edit/Back이라는 입력 사실만 signal로 올린다.
- Study가 WrongCount, 세션 이동, 저장을 해석한다.
- Tween kill, parallel, transition, ease, finished 흐름을 옮긴다.
- 애니메이션 중 중복 입력을 막는다.
- 현재 카드 편집·삭제 후 세션 연속성을 보존한다.

조작감 상수는 포팅 중 변경하지 않는다. 기존 동작 재현 후 사람의 사용 확인을 거쳐 별도 조정한다.

#### 학습 목표

- `_process`와 입력 이벤트의 차이
- 로컬·글로벌 좌표
- Control pivot, rotation, position, scale
- Tween의 생명주기와 완료 signal
- 입력 잠금과 상태 머신
- View가 규칙을 해석하지 않아야 하는 이유

#### 미니 실습

- 애니메이션 중 Again 버튼을 연속 입력해 중복 처리가 없는지 확인한다.
- Tween 완료 전후의 카드 위치와 입력 상태를 Remote Inspector로 본다.

#### 완료 기준

- Again은 WrongCount를 한 번 올리고 다음 카드로 간다.
- Good은 WrongCount를 바꾸지 않고 다음 카드로 간다.
- 마지막 카드 후 완료 화면이 뜬다.
- 편집 후 현재 세션이 초기화되지 않는다.
- 카드 모션이 기존과 기능적으로 동일하다.

### Phase 9 — App 조립과 전체 흐름

#### 대상

- `App.cs` → `app.gd`
- `app.tscn`의 루트 script

#### 구현 작업

- 모든 화면 signal을 App에서 연결한다.
- 현재 덱, 편집 index, 편집 전 값, 돌아갈 화면 상태를 옮긴다.
- 덱 관리와 카드 편집 저장 흐름을 옮긴다.
- 질문 변경 시 진행도 rename을 적용한다.
- 학습 화면에서 편집기로 갔다가 다시 같은 세션으로 돌아온다.
- 시작 시 마지막 덱이 있으면 허브, 없으면 덱 목록으로 간다.

#### 학습 목표

- Composition Root의 역할
- 상위 조정자와 하위 View 사이의 의존 방향
- 화면 상태와 도메인 상태의 차이
- signal 기반 화면 전환
- 결합도가 높은 코드에서 책임 경계를 읽는 방법

#### 미니 실습

- signal 하나의 흐름을 입력 노드부터 저장 파일까지 손으로 그린다.
- App을 직접 참조하지 않고 새 화면이 요청 signal만 올리는 이유를 설명한다.

#### 완료 기준

- 앱 시작부터 덱 선택, 학습, 편집, 종료까지 전체 흐름이 이어진다.
- App smoke test와 메뉴 action test가 GDScript에서 통과한다.
- View가 `DeckStorage`나 App을 직접 호출하지 않는다.

### Phase 10 — 테스트 이전과 회귀 검증

#### 구현 작업

- `TestRunner.cs`의 테스트를 GDScript로 옮긴다.
- 최소한 core/storage/scene/app 그룹으로 나눈다.
- 하나의 예외로 `get_tree().quit()`에 도달하지 못하는 구조를 피한다.
- 실패 개수를 프로세스 종료 코드로 돌려준다.
- headless 실행 명령을 문서화한다.

외부 테스트 플러그인은 필수가 아니다. 먼저 현재의 작은 자체 runner를 GDScript로 옮기고, 테스트 수와 유지 비용이 커질 때 GUT 같은 프레임워크를 별도 평가한다.

#### 학습 목표

- headless Godot 실행
- SceneTree 종료 코드
- 씬 인스턴스 테스트와 순수 로직 테스트의 차이
- signal을 직접 발신하는 smoke test의 한계
- 자동 테스트와 사람의 화면 판정 경계

#### 완료 기준

- core, storage, scene, app 검증이 모두 일반 Godot에서 통과한다.
- 실패가 발생하면 hang 대신 실패 항목과 종료 코드를 확인할 수 있다.
- 클릭 감각, 애니메이션, 파일 대화상자는 별도 수동 체크리스트로 검증한다.

### Phase 11 — C#/.NET 제거

이 단계는 앞 단계가 모두 통과한 뒤에만 수행한다.

#### 제거 대상

- 모든 `.cs`와 `.cs.uid`
- `MyFlashCard.csproj`
- `MyFlashCard.sln`
- `tests/TestRunner.cs`
- `.NET` 실행 절차와 더 이상 유효하지 않은 문서
- `project.godot`의 `[dotnet]`과 `config/features`의 `"C#"`

프로젝트 설정은 기존 규칙대로 `src/debug/apply_project_settings.gd`를 출처로 수정한다. `project.godot`만 단독으로 고치지 않는다.

#### 최종 검증

- 일반 Godot 에디터로 프로젝트를 새로 import한다.
- 모든 `.tscn`에서 `.cs` 경로가 사라졌는지 검색한다.
- headless 테스트를 깨끗한 import 상태에서 실행한다.
- 기존 덱과 진행도 복사본으로 전체 흐름을 실행한다.
- desktop export를 실행한다.
- 그 다음 Android export 준비로 넘어간다.

#### 완료 기준

- 저장소에서 C# 참조를 검색해 결과가 없다.
- 일반 Godot 빌드만으로 개발, 테스트, export가 가능하다.
- `README`, `AGENT`, `CODE_GUIDE`, `ROADMAP`이 실제 GDScript 구조와 일치한다.

## 8. 단계별 커밋 권장 단위

각 커밋은 되도록 하나의 책임과 그 테스트를 함께 담는다.

```text
test: GDScript 테스트 러너 기준선 추가
feat: core 데이터 모델을 GDScript로 이전
feat: Markdown parser와 writer를 GDScript로 이전
feat: 진행도와 세션 규칙을 GDScript로 이전
feat: 덱 저장소를 GDScript로 이전
feat: 재사용 카드 UI를 GDScript로 이전
feat: 목록 화면을 GDScript로 이전
feat: 앱 테마를 GDScript로 이전
feat: Study 흐름과 모션을 GDScript로 이전
feat: App 조립을 GDScript로 이전
chore: C#과 .NET 프로젝트 의존성 제거
docs: GDScript 구조와 실행 절차 갱신
```

커밋마다 C# 파일을 바로 삭제할 필요는 없다. 비교 기준이 더 이상 필요 없고 해당 책임의 GDScript 검증이 완료됐을 때 정리한다.

## 9. 수동 회귀 체크리스트

자동 테스트가 통과해도 다음은 사람이 직접 확인한다.

### 시작과 덱 관리

- 마지막 덱이 있으면 해당 덱 허브로 시작한다.
- 마지막 덱이 삭제됐으면 덱 목록으로 시작한다.
- 새 덱 이름 충돌 시 `(2)`가 붙는다.
- rename, duplicate, delete가 진행도 파일과 함께 동작한다.
- Import와 Export의 네이티브 대화상자가 열린다.
- 덱 폴더 변경 후 그 폴더의 덱만 보인다.

### 카드 편집

- 카드 추가, 수정, 복제, 삭제가 Markdown에 반영된다.
- 아무것도 바꾸지 않고 나오면 Markdown을 다시 쓰지 않는다.
- 질문을 바꾸면 WrongCount와 상태가 새 질문으로 이동한다.
- 빈 질문으로 나오면 기존 카드가 사라지지 않는다.
- 중복 질문의 기존 동작이 유지된다.

### 학습

- 앞면 탭으로 답이 보이고 다시 탭하면 앞면으로 돌아온다.
- Again과 Good의 시각적 무게가 대등하다.
- Again만 WrongCount를 올린다.
- Sequential과 Shuffle이 구분된다.
- 마지막 카드 뒤 완료 화면과 재시작이 동작한다.
- Study 중 편집·삭제 후 세션이 자연스럽게 이어진다.
- 애니메이션 중 입력이 중복 처리되지 않는다.

### 화면과 테마

- 375×667 창과 720×1280 기준 viewport에서 레이아웃이 유지된다.
- 긴 질문과 답이 스크롤된다.
- 카드 비율 0.7이 유지된다.
- popup, dialog, hover, pressed, focus 상태가 읽기 쉽다.
- Pretendard 한글 렌더링이 정상이다.

## 10. 중단 및 복구 기준

다음 상황에서는 다음 계층으로 진행하지 않고 현재 단계를 먼저 복구한다.

- 기존 데이터 fixture를 읽지 못한다.
- 씬을 열 때 missing script 또는 parse error가 발생한다.
- 같은 입력에서 C#과 GDScript 결과가 다르지만 이유를 설명할 수 없다.
- 테스트가 실패 대신 hang한다.
- View가 저장소나 상위 화면을 직접 호출하기 시작한다.
- 포팅과 무관한 UX 변경이 같은 diff에 섞인다.

복구 순서는 다음과 같다.

1. 실패를 가장 작은 입력이나 단독 씬으로 재현한다.
2. 기존 C# 테스트와 구현의 계약을 다시 확인한다.
3. GDScript의 타입, null, 배열 복사, signal 연결 수를 확인한다.
4. Remote Scene Tree와 Debugger로 실제 노드 상태를 확인한다.
5. 고친 뒤 해당 단계 전체 테스트를 다시 실행한다.

## 11. 마이그레이션 이후 학습 과제

전환을 완료한 뒤에는 다음을 작은 독립 과제로 진행한다.

1. 현재 코드 기반 Theme 일부를 `.tres`로 만들어 차이를 비교한다.
2. 키보드/마우스 입력과 터치 드래그를 통합하는 스와이프 입력 계층을 만든다.
3. 실제 Android export와 실기기 테스트를 수행한다.
4. Android 외부 폴더 접근을 위한 SAF 선택지를 조사한다.
5. App에서 카드 편집 책임을 별도 서비스로 분리해 본다.
6. Resource 기반 데이터 모델이 현재 RefCounted 모델보다 유리한지 작은 실험으로 비교한다.
7. profiler와 debugger로 동적 노드와 Tween 생명주기를 관찰한다.

이 과제들은 마이그레이션 완료 판정에 포함하지 않는다. 먼저 기존 앱을 안정적으로 GDScript로 옮기고, 이후 Godot 고유 기능을 활용하는 방향으로 개선한다.

## 12. 최종 자기 점검

다음 질문에 코드나 Scene Tree를 가리키며 답할 수 있으면 학습 목표도 달성한 것으로 본다.

- 왜 `FlashCard`는 Node가 아니라 RefCounted인가?
- Scene과 script, PackedScene 인스턴스는 각각 무엇인가?
- signal을 직접 메서드 호출 대신 쓰는 경계는 어디인가?
- `@onready`와 `_ready()`는 언제 실행되는가?
- Container 아래에서 Control의 위치와 크기는 누가 결정하는가?
- `res://`와 `user://`는 export 후 어떻게 다른가?
- Progress가 파일 IO를 몰라야 하는 이유는 무엇인가?
- View가 Again을 WrongCount 증가로 해석하면 왜 결합도가 커지는가?
- Tween 도중 입력을 막지 않으면 어떤 중복 상태가 생기는가?
- C# 파일을 제거해도 기존 사용자 데이터가 유지된다고 어떻게 증명했는가?
