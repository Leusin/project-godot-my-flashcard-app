# Mobile Foundation

Godot 4.7용 공통 입력과 레이아웃 모듈입니다. 앱의 데이터, 테마, 저장소에 의존하지 않으며 별도의 에디터 플러그인 설정 없이 사용합니다.

## 설치

1. `addons/mobile_foundation/` 폴더를 프로젝트에 복사합니다.
2. Godot 에디터로 프로젝트를 열거나 아래 명령으로 전역 클래스를 등록합니다.

```sh
godot --headless --path . --import
```

- 기존 프로젝트와 `class_name` 중복 시 이름 변경 필요
- 앱 전용 동작은 모듈 밖에서 처리

## 모듈

| 클래스 | 파일 | 역할 |
| --- | --- | --- |
| DragBounds | `input/drag_bounds.gd` | 입력 영역의 조상 노드 탐색과 드래그 위치 계산 |
| AspectFit | `layout/aspect_fit.gd` | 종횡비를 유지하는 중앙 사각형 계산 |
| ReorderGesture | `ui/reorder_gesture.gd` | 탭, 스크롤, 긴 누르기, 드래그 구분 |
| SafeArea | `ui/safe_area.gd` | 안전 영역을 viewport 여백으로 변환 |
| KeyboardInsetAvoider | `ui/keyboard_avoider.gd` | 가상 키보드에 가려진 입력창 위치 보정 |

## 입력

`ReorderGesture`의 `surface`에 입력을 받을 Control을 지정하고, 해당 노드의 `gui_input`을 `feed(event)`에 연결합니다.

| 항목 | 용도 |
| --- | --- |
| `hold_seconds` | 긴 누르기 대기 시간, 앱의 덱 타일은 INF로 집기 비활성화 |
| `scrolled(offset)` | 스크롤 이동 알림 |
| `picked`, `dragged(offset)`, `dropped(pointer)` | 집기, 드래그, 놓기 알림 |
| `blocks_selection` | 참인 동안 버튼 선택 동작 차단 |
| `cancel()` | 진행 중인 입력 취소 |

- 터치는 Godot 마우스 에뮬레이션 사용
- ScrollContainer의 `scroll_started`를 gesture의 `scroll_started()`에 연결
- 위치 변경과 연출은 사용하는 화면에서 처리

`DragBounds.clip_ancestor(item)`으로 스크롤 컨테이너를 찾을 수 있습니다. 드래그 위치를 제한할 때는 `clamped()`를 사용합니다.

```gdscript
var clip := DragBounds.clip_ancestor(item)
item.position = DragBounds.clamped(desired_position, item, clip)
```

## 레이아웃

| API | 용도 |
| --- | --- |
| `AspectFit.centered_rect(available, aspect_ratio)` | 주어진 영역 안에서 비율을 유지하는 중앙 사각형 |
| `SafeArea.current_insets(viewport_size)` | 현재 안전 영역의 여백, 좌상우하 순서의 Vector4 |
| `SafeArea.insets_in_viewport(safe_area, window_size, viewport_size)` | 창 픽셀을 viewport 좌표로 변환 |
| `KeyboardInsetAvoider.keyboard_padding` | 입력창과 키보드 사이 여백, 기본 24 |
| `KeyboardInsetAvoider.top_padding` | 화면 위쪽 최소 여백, 기본 16 |
| `KeyboardInsetAvoider.avoid_target` | 입력창 대신 이동시킬 노드의 경로 |

- `aspect_ratio`는 너비 / 높이
- KeyboardInsetAvoider는 가상 키보드를 지원하는 플랫폼에서만 동작
- 키보드가 닫히거나 노드가 숨겨지면 기존 위치 복원

## 테스트

`MobileFoundationChecks.run(report)`에 결과를 받을 Callable을 전달합니다.

```gdscript
MobileFoundationChecks.run(
	func(passed: bool, description: String) -> void:
		print(("PASS: " if passed else "FAIL: ") + description)
)
```

이 프로젝트에서는 `tests/mobile_foundation_smoke.gd`를 통해 전체 테스트에 포함됩니다. 실행 명령은 [개발 가이드](../../docs/DEVELOPMENT.md#테스트)에 있습니다.
