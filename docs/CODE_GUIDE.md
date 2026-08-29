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
    ├─ 새 학습 설정 → Study → Result
    ├─ 이어서 학습 ────────┘
    └─ 카드 관리 → Card List → Card Detail → Card Editor
  └─ 덱 추가
      ├─ 새 덱 → 이름 입력 → 첫 Card Editor
      ├─ Markdown 파일 가져오기 → Library
      └─ 클립보드 Markdown → 이름 입력 → Card List
```

- 덱 타일 `⋮`와 추가 타일 `+`는 각 anchor 아래에 context list를 연다.
- Study 카드 전체가 탭·드래그 영역이다. 버튼은 PC 입력을 위해 카드 밖에 유지한다.
- Card Detail은 카드와 Header의 `⋮`를 분리해 카드 전체 탭이 가려지지 않게 한다.
- 결과 행에서 카드를 열면 같은 Card Detail을 재사용하고 결과 화면으로 돌아간다.

## 저장 위치

```text
user://decks/<덱>.md
user://progress/<덱>.json
user://study_resume/<덱>.json
user://settings.json
```

- Markdown 덱이 원본 데이터다.
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
