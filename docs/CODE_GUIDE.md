# 코드 읽기 가이드

현재 앱은 GDScript만으로 실행된다. 진입점은 `src/main/main.tscn`, 화면과 앱 상태를 조정하는 composition root는 `src/main/main.gd`다.

## 읽는 순서

| 순서 | 파일 | 책임 |
| --- | --- | --- |
| 1 | `src/core/flash_card.gd` · `card_status.gd` | 카드 데이터와 학습 상태 값 |
| 2 | `src/core/deck_parser.gd` · `deck_writer.gd` | Markdown ↔ 카드 배열 |
| 3 | `src/core/study_session.gd` · `deck_ordering.gd` | 현재 카드, 이전/다음, 학습 순서 |
| 4 | `src/core/progress.gd` · `study_resume.gd` · `app_settings.gd` | 덱별 학습 기록과 이어서 학습 데이터 |
| 5 | `src/core/deck_naming.gd` · `deck_info.gd` · `card_row.gd` · `card_ordering.gd` · `deck_library_order.gd` | 이름 규칙, 목록 데이터, 카드/덱 순서 (자리 옮기기 자체는 `ArrayOrder`) |
| 6 | `src/storage/deck_storage.gd` | 덱·진행도·설정·이어하기 파일 IO |
| 7 | `src/main/main.tscn` · `main.gd` | 화면 전환, 덱 관리, 학습 판정, 편집 저장 |
| 8 | `src/main/study_gesture_surface.gd` | 탭·드래그 판정과 카드 이동/플립 애니메이션 |
| 9 | `src/main/card_detail_surface.gd` | 카드 상세 보기의 탭과 플립 애니메이션 |
| 10 | `src/main/*_view.tscn` · 작은 row/tile 씬 | 편집 가능한 화면 골격과 반복 UI |
| 11 | `tests/test_runner.gd` · `phase*_smoke.gd` · `main_smoke.gd` | 순수 로직, 저장소, 전체 앱 smoke test |

앱과 무관한 바닥 기능은 [`addons/mobile_foundation/`](../addons/mobile_foundation/README.md)에 따로 있다.
끌기 범위(`DragBounds`), 삽입 위치(`ListInsertion`), 배열 자리 옮기기(`ArrayOrder`),
종횡비 맞춤(`AspectFit`), 안전 영역(`SafeArea`), 가상 키보드 피하기(`KeyboardInsetAvoider`)가 거기 산다.
`ListReorder`는 공통 프레임워크의 놓기 위치 계산·자식 순서 변경을 제공한다. 앱의 덱·카드 목록은 정렬 기준 선택을 사용하며 직접 재정렬하지 않는다.
화면은 `begin`/`finish`를 전달하고 `reordered`에서 도메인 index 갱신·저장을 연결한다.
`ReorderGesture`는 긴 누르기/즉시 집기, 스크롤 구분과 입력 취소를 맡는다.
row/tile은 입력 signal을 연결하고 들어 올리는 연출을 담당한다.
독립 예제는 `addons/mobile_foundation/examples/reorder_demo.tscn`이다.
다른 프로젝트로 폴더째 복사할 수 있도록 `res://src/`를 모른다.

## 의존 방향

```text
main.gd
├─ src/main/*.tscn, 작은 UI script
├─ DeckStorage
├─ src/core/*
└─ addons/mobile_foundation/*

DeckStorage → src/core/*
src/core/* → Godot UI와 파일 IO를 모름
addons/mobile_foundation/* → 이 앱을 모름 (반대 방향 의존은 없다)
```

입력 표면은 `tapped`, `swiped`, 버튼 `pressed` 같은 사실만 전달한다. AGAIN/GOOD 처리, 진행도 저장, 다음 화면 선택은 `main.gd`가 맡는다.

## 화면 흐름

```text
Deck Library
  ├─ 덱 선택 → Study Ready
    ├─ 진행도 아래 범위·순서 선택 → 학습 시작 → Study → Result
    ├─ 이어서 학습 ────────┘
    └─ 카드 관리 → Card List → Card Detail → Card Editor
  └─ 덱 추가
      ├─ 새 덱 → 이름 입력 → 첫 Card Editor
      ├─ Markdown 파일 가져오기 → Library
      └─ 클립보드 Markdown → 이름 입력 → Card List
```

- 덱 타일 `⋮`와 추가 타일 `+`는 각 anchor 아래에 context list를 연다.
- 학습 준비의 막대는 덱 전체의 완료 비율이다. `StudyReadyView`는 저장된 세션의 범위·순서를 받아 현재 설정과 비교하고 이어하기 또는 새로 시작 버튼을 강조한다. 설정 변경은 저장된 세션을 바꾸지 않는다. 유효한 이어하기 세션이 있을 때 새로 시작은 확인창을 거치며, 취소·뒤로가기는 진행 위치를 보존한다.
- Study 카드 전체가 탭·드래그 영역이다. 앞면에는 답 보기, 뒷면에는 다시 볼게요 / 기억나요 버튼을 카드 밖에 표시한다. 답 영역은 질문·오답 tally와 독립적으로 카드 중심에 배치하며, 긴 답은 왼쪽 정렬과 스크롤을 사용한다. 뒷면에서 오답 tally는 유지하고 상태 배지는 숨긴다.
- Card Detail은 카드와 Header의 `⋮`를 분리해 카드 전체 탭이 가려지지 않게 한다.
- 결과 행에서 카드를 열면 같은 Card Detail을 재사용하고 결과 화면으로 돌아간다.
- Card List 검색은 질문·답의 대소문자를 구분하지 않는 부분 일치다. 숨긴 행도 원래 카드 index를 유지하며, 검색 중에는 순서 변경 손잡이를 숨긴다.

## 저장 위치

```text
user://decks/<덱>.md
user://progress/<덱>.json
user://study_resume/<덱>.json
user://settings.json
```

- Markdown 덱이 원본 데이터다.
- 덱·진행도·이어하기·설정은 같은 폴더의 `.pending`에 쓰고 flush 성공 후 교체한다. 동기 저장용이며 동시 writer는 지원하지 않는다.
- 덱 이름 변경은 목적지 충돌을 먼저 검사하고 관련 기록을 옮긴 뒤 Markdown을 옮긴다. 중간 실패 시 역순으로 복원한다. 여러 파일의 전원 차단 시점까지 원자성을 보장하는 트랜잭션은 아니다.
- 클립보드 생성은 파싱으로 형식을 확인한 뒤 복사한 Markdown 원문을 그대로 저장한다.
- 진행도와 이어서 학습은 덱별 파생 JSON이다.
- 질문 문자열이 카드 기록의 식별자이므로 질문 편집 시 `Progress.rename`으로 기록을 옮긴다.
- Import/Export 실패 원인은 `DeckStorage.ExportResult` 등 구체적인 결과로 구분한다.

## 씬 수정 시 확인할 것

1. Unique Name 또는 노드 경로를 바꾸면 `main.gd`의 `@onready` 경로를 찾는다.
2. 전체 카드 위에 `Control`을 덮을 때 `mouse_filter`가 실제 탭 버튼을 가리지 않는지 확인한다.
3. Container 자식의 위치는 anchor보다 Container sizing의 영향을 먼저 받는다.
4. 메뉴 위치는 global 좌표를 overlay 로컬 좌표로 변환한 뒤 viewport 안으로 clamp한다.
5. 에디터에서 저장한 `.tscn`의 UID·노드 순서 diff와 기능 변경을 구분한다.

## 테스트

```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . --log-file .godot/latest-test.log res://tests/tests.tscn
```

`RESULT: N checks, 0 failures`를 확인한다. signal을 직접 발신하는 테스트만으로는 실제 pointer hit-test 버그를 놓칠 수 있으므로, 클릭 영역이 중요한 UI는 실제 `InputEventMouseButton` 경로도 검증한다.


`tests/ui_interaction.gd`는 실제 포인터 이벤트를 화면에 보내 덱 선택·길게 누른 뒤 순서 유지·카드 정렬 후 검색 결과 선택을 검사한다.
실제 앱 데이터와 분리한 프로젝트 복사본에서 실행한다.

```sh
godot --headless --path . --script res://tests/ui_interaction.gd
# 렌더링한 카드 목록과 검색 화면을 build/ 아래에 캡처
godot --path . --script res://tests/ui_interaction.gd -- --capture
```

- 학습 결과는 한국어 판정 라벨을 사용한다. 재학습 대상이 있으면 장수를 포함한 복습 버튼을 강조하고, 없으면 해당 버튼을 숨긴다. 학습 준비로 버튼은 단독 표시 시에도 흰 배경과 검은 글자를 유지한다.

- 카드 목록은 Main이 전달한 Progress에서 오답 횟수를 읽어 행에 표시한다. 0회 표식은 숨기고 5회 초과는 막대를 숨기고 총횟수만 일반체로 표시한다. 목록 전용 행 그림자 조정은 결과 화면에 적용하지 않는다.

- 카드 목록의 오답 표식은 질문 옆에 표시한다. 검색어가 있으면 카드 추가 버튼을 숨기며 지우면 복원한다.

- inline_question_row.gd는 질문의 실제 글자 너비에 맞춰 오답 표식을 붙이고 긴 질문에서는 표식 공간을 확보한 뒤 말줄임한다.

- 덱 목록의 DeckInfo는 완료 장수를 포함한다. Main이 현재 덱의 카드 상태를 집계하고 타일은 완료 N / 전체장으로 표시한다.

- AppSettings의 DeckSort(name/recent)와 RecentDecks가 덱 정렬 기준·최근 학습 이력을 보존한다. DeckLibraryOrder.sorted_files는 이름 자연 정렬과 최근 이력 우선 정렬을 담당한다. DeckOrder는 이전 설정 호환용이며 새 정렬에 사용하지 않는다.

- 카드 목록은 AppSettings.CardSort(0 기본, 1 질문, 2 오답)로 행의 표시 순서를 선택한다. row.card_index는 원본 index이며 검색과 행 동작에서도 그대로 사용한다. 정렬은 파일·학습 순서·이어하기를 변경하지 않는다.

- 카드 추가는 헤더의 ＋ 버튼을 사용하며 검색어가 있는 동안 숨긴다.

### 공통 컨텍스트 메뉴

- `src/main/context_menu.tscn`이 패널, 항목 템플릿, 구분선, 닫기 영역을 정의한다. `anchored_popup_menu.gd`의 `add_item`, `add_separator`, `set_radio`, `open_at`으로 구성한다.
- 추가·덱·카드·라이브러리 메뉴 씬은 이 씬을 상속하며 각 스크립트는 항목과 의미별 signal만 담당한다.
- `CardListView`도 같은 씬을 CanvasLayer에 표시하며 단일 정렬 선택과 닫힘을 처리한다. Main은 뒤로가기 시 화면 이동보다 메뉴 닫기를 먼저 처리한다.
- `context_menu_panel.tres`가 검은 3px 테두리와 패널 여백·그림자를 공유한다. 학습 설정의 기본 PopupMenu에도 같은 패널 스타일을 사용한다.

- `ModalDialog.emphasize_secondary`는 보조 동작을 검게 강조하는 선택 옵션이다. 편집 취소 확인창은 계속 편집을 강조하며, 기존 primary/secondary signal 연결은 그대로 유지한다.
