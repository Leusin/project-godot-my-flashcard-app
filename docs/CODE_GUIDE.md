# 코드 읽기 가이드

진입점은 `src/main/main.tscn`이다. `main.gd`가 화면과 서비스를 연결한다. 제품 동작은 [DESIGN](DESIGN.md), 설계 규칙은 [CONVENTIONS](CONVENTIONS.md)를 참고한다.

## 책임과 읽는 순서

| 위치 | 책임 |
| --- | --- |
| `src/core/flash_card.gd`, `card_status.gd` | 카드 데이터와 상태 |
| `src/core/deck_parser.gd`, `deck_writer.gd` | Markdown ↔ 카드 배열 |
| `src/core/study_session.gd`, `study_plan.gd`, `study_resume.gd` | 현재 위치, 범위·원본 인덱스 매핑, 이어하기 검증 |
| `src/core/progress.gd`, `app_settings.gd` | 학습 기록과 설정 직렬화 |
| `src/core/*ordering.gd`, `deck_library_order.gd` | 학습·목록 정렬 |
| `src/storage/deck_storage.gd`, `app_backup.gd` | 파일 IO, 안전한 교체, ZIP 백업·복원 |
| `src/main/main.gd` | 화면 전환, signal 연결, 오류 알림과 작업 조정 |
| `src/main/deck_action_service.gd`, `deck_action_result.gd` | 덱 생성·가져오기·복제·이름 변경·삭제 결과 |
| `src/main/card_workspace.gd`, `card_edit_coordinator.gd` | 편집 스냅샷·저장, 진행 중 학습에 편집 반영 |
| `src/main/study_run.gd`, `study_flow_view.gd` | 판정·기록·결과·이어하기 저장 / 학습 화면 표시 |
| `src/main/back_navigation.gd` | 뒤로가기 우선순위 결정 |
| `src/main/*_view.tscn`, 작은 row/tile 씬 | 화면 골격과 반복 UI |

`src/core/`는 Scene Tree와 파일 IO를 모른다. storage는 core를 사용하며 UI를 모른다. main 계층의 서비스는 저장소를 호출할 수 있다. 작은 UI는 signal로 동작을 알리고 main이 서비스와 화면 전환을 연결한다.

## 수정할 기능별 시작점

- **목록·검색·정렬:** `library_view.gd`, `card_list_view.gd`. 행의 `card_index`는 정렬·필터 후에도 원본 인덱스다. 표시 순서를 저장 순서로 쓰지 않는다.
- **학습 범위·이어하기:** `StudyPlan` → `StudyRun` → `main.gd`. 남은 인덱스와 덱 해시를 함께 유지한다.
- **편집 저장:** `CardEditCoordinator` → `CardWorkspace` → `DeckStorage`. Markdown 저장 성공과 진행도 저장 성공을 별도로 반환한다.
- **탭·스와이프·애니메이션:** `study_gesture_surface.gd`, `card_detail_surface.gd`. 판정 의미와 저장은 입력 표면 밖에서 처리한다.
- **오답 표식:** `wrong_tally.gd`, `inline_question_row.gd`. 긴 질문에서도 표식 공간을 먼저 확보한다.

## 공통 UI

- `context_menu.tscn`과 `anchored_popup_menu.gd`가 메뉴 패널·항목·구분선·닫힘을 공유한다. 개별 메뉴는 상속 씬에서 항목과 signal만 구성한다. 카드 목록 정렬도 같은 씬을 쓴다.
- 메뉴는 `open_at`으로 기준 버튼을 받는다. 열린 동안 `frame_pre_draw`에서 위치를 갱신하며, `get_global_transform_with_canvas()`로 CanvasLayer 간 좌표를 변환한다.
- `context_menu_panel.tres`는 공통 메뉴 스타일이다. 학습 설정의 기본 PopupMenu도 같은 패널 스타일을 쓴다.
- `settings_action_row.tscn`은 설정의 공통 버튼 행이다. 내부 라벨은 입력을 가로채지 않는다.
- `ModalDialog.emphasize_secondary`는 보조 버튼을 강조하되 signal 의미를 유지한다.
- 버튼의 hover 스타일은 normal과 같게 유지하며 pressed와 focus는 별도다.

앱과 독립적인 입력·배열·레이아웃·안전 영역·키보드 처리는 [Mobile Foundation](../addons/mobile_foundation/README.md)에 있다. `ListReorder`와 `ReorderGesture`를 결합한 직접 재정렬은 addon 예제에서 확인한다. 앱 목록은 정렬 기준 선택을 사용한다.

## 저장 위치와 제약

```text
user://decks/<덱>.md
user://progress/<덱>.json
user://study_resume/<덱>.json
user://settings.json
```

- Markdown이 카드 원본이다. 진행도는 질문 문자열, 이어하기는 덱 해시와 원본 인덱스에 의존한다.
- 일반 저장은 같은 폴더의 `.pending`에 쓰고 flush 성공 후 교체한다. 동시 writer는 지원하지 않는다.
- 덱 이름 변경은 충돌 검사 후 관련 기록, Markdown 순서로 옮기고 실패하면 역순 복원을 시도한다. 여러 파일에 걸친 전원 차단까지 원자적으로 보장하지는 않는다.
- 설정은 기존 값을 읽고 필요한 필드만 바꾼 뒤 저장한다.

## 검증

실행 명령은 [README](../README.md#실행과-검증)를 따른다. `tests/test_runner.gd`가 core·storage·앱 smoke test를 실행한다. 재사용 모듈 검증은 `tests/mobile_foundation_smoke.gd`가 연결한다.

씬 변경 시 실제 노드 타입·Unique Name·`@onready` 경로와 `tests/main_smoke.gd`를 함께 확인한다. 클릭 영역은 signal 발신만으로 검증하지 않고 `tests/ui_interaction.gd`의 실제 포인터 경로로 확인한다. 창 크기를 바꾼 뒤 메뉴 위치도 확인한다.

전체 화면 Control의 `mouse_filter`, Container가 결정하는 자식 배치, 전환 중 입력 잠금을 확인한다. 화면 감각은 별도 실행 창과 모바일에서 검토한다. 반복된 실패의 원인과 방지법은 [DEVLOG](DEVLOG.md)에 정리한다.
