# Mobile Foundation

모바일 Godot 앱에서 되풀이되는 바닥 기능을 모은 runtime 모듈이다.
끌어 놓기, 목록 순서, 안전 영역, 가상 키보드처럼 앱 종류와 상관없이 똑같이 필요한 것만 담았다.

editor plugin이 아니다. `plugin.cfg`도 없고 켜고 끌 것도 없다.
`class_name`으로 전역 등록되므로 폴더만 있으면 어디서든 바로 부른다.

- Godot 4.7
- 의존: Godot 표준 클래스뿐 (`Control`, `MarginContainer`, `DisplayServer`, `OS`)
- 앱 문구, 테마, 저장소, 도메인 타입에 기대지 않는다

## 새 프로젝트로 옮기기

1. `addons/mobile_foundation/` 폴더를 통째로 복사한다.
2. Godot 에디터로 프로젝트를 한 번 연다. 헤드리스라면 `godot --headless --path . --import`를 부른다.
   전역 class 이름은 이때 등록된다. 이 단계를 건너뛰면 "Identifier not declared" 오류가 난다.
3. 끝이다. `DragBounds`, `ListInsertion` 같은 이름을 바로 쓸 수 있다.

`class_name`은 전역이라 이름이 겹치면 프로젝트가 열리지 않는다.
이미 같은 이름을 쓰고 있다면 그쪽이나 이쪽 중 하나를 고쳐야 한다.

## 폴더

```text
addons/mobile_foundation/
├─ input/
│  ├─ drag_bounds.gd      DragBounds
│  └─ list_insertion.gd   ListInsertion
├─ collections/
│  └─ array_order.gd      ArrayOrder
├─ layout/
│  └─ aspect_fit.gd       AspectFit
├─ ui/
│  ├─ list_reorder.gd    ListReorder (노드)
│  ├─ reorder_gesture.gd ReorderGesture (노드)
│  ├─ safe_area.gd        SafeArea
│  ├─ safe_area_margin.gd SafeAreaMargin (노드)
│  └─ keyboard_avoider.gd KeyboardInsetAvoider (노드)
├─ examples/
│  ├─ reorder_demo.tscn  독립 목록/타일 예제
│  └─ reorder_demo.gd
├─ tests/
│  └─ mobile_foundation_checks.gd  MobileFoundationChecks
└─ README.md
```

`input/`, `collections/`, `layout/`은 순수 계산이다. 화면도 노드도 모른다.
`ui/`만 Godot 노드와 `DisplayServer`를 안다.

---

## DragBounds

집어 든 항목이 잘려 보이지 않도록, 끄는 자리를 보이는 영역 안으로 묶는다.
목록 재정렬, 인벤토리 칸 옮기기, 핫바 슬롯 끌기에 그대로 쓴다.

| 함수 | 하는 일 |
| --- | --- |
| `clip_ancestor(node, clip_class := "ScrollContainer") -> Control` | 항목을 잘라 내는 조상 노드를 찾는다. 없으면 `null` |
| `clamped(desired, item, clip) -> Vector2` | `item`의 부모 좌표계에서 `clip` 안으로 묶는다. `clip`이나 부모가 없으면 `desired` 그대로 |
| `clamped_position(desired, item_size, item_scale, pivot_offset, bounds) -> Vector2` | 노드 없이 계산만. 테스트하기 좋은 순수 함수 |

집은 항목을 키우면 `pivot_offset`을 축으로 layout 사각형 밖까지 커질 수 있다.
`item_scale`과 pivot을 함께 받는 이유가 그것이다. 삐져나온 폭까지 감안해야 테두리가 잘리지 않는다.
항목이 영역보다 크면 묶을 자리가 없으므로 시작 지점에 둔다.

```gdscript
var _clip: Control

func _ready() -> void:
	_clip = DragBounds.clip_ancestor(self)

func _on_drag(desired: Vector2) -> void:
	position = DragBounds.clamped(desired, self, _clip)
```

인벤토리 판처럼 `ScrollContainer`가 아닌 노드가 잘라 낸다면 class 이름을 넘긴다.

```gdscript
_clip = DragBounds.clip_ancestor(self, "PanelContainer")
```

## ListInsertion

가리킨 경계를 최종 index로 바꾼다. 화면 좌표는 다루지 않는다.
어느 항목의 앞/뒤를 가리켰는지 정하는 것은 부르는 쪽 몫이고, 이 모듈은 그 다음의 셈만 맡는다.

| 함수 | 하는 일 |
| --- | --- |
| `target_index(item_count, moving_index, anchor_index, after_anchor) -> int` | 이미 목록 안에 있는 항목을 옮겼을 때의 최종 index. 옮길 수 없으면 `-1` |
| `insertion_index(item_count, anchor_index, after_anchor) -> int` | 바깥에서 가져온 새 항목을 끼워 넣을 자리. `0..item_count` |

`target_index()`는 움직이는 항목을 먼저 빼고 세므로, 끌어 온 자리와 결과가 한 칸 다를 수 있다.
경계가 움직이는 항목 자체거나, index가 범위 밖이거나, 항목이 하나뿐이면 `-1`이다.

`insertion_index()`는 빼는 항목이 없으므로 끝에 붙이면 `item_count`가 된다.
`Array.insert()`에 그대로 넘길 수 있다.

```gdscript
# 목록 안에서 자리 옮기기
var target := ListInsertion.target_index(
	rows.get_child_count(), moving_index, anchor_index, after_anchor
)
if target >= 0:
	items = ArrayOrder.moved(items, moving_index, target)

# 다른 칸에서 끌어온 항목 끼워 넣기
slots.insert(ListInsertion.insertion_index(slots.size(), anchor_index, after_anchor), item)
```

## ListReorder (노드)

세로 목록(`VERTICAL`)과 줄바꿈 타일 목록(`FLOW`)에서 놓을 경계를 찾고,
Container 자식 순서를 바꾼 뒤 `reordered(from_index, to_index)`를 보낸다.
긴 누르기, 손잡이 드래그 등 어떤 입력으로 시작했는지는 알지 않는다.

```gdscript
var reorder := ListReorder.new()

func _ready() -> void:
	reorder.items = $Scroll/Rows
	# HFlowContainer라면 ListReorder.Layout.FLOW
	reorder.layout = ListReorder.Layout.VERTICAL
	add_child(reorder)
	reorder.reordered.connect(_on_reordered)

func _on_pick(item: Control) -> void:
	reorder.begin(item)

func _on_drop(item: Control, canvas_pointer: Vector2) -> void:
	reorder.finish(item, canvas_pointer)

func _on_reordered(from_index: int, to_index: int) -> void:
	# 화면 순서는 이미 바뀌었다. 앱 데이터 순서와 저장만 처리한다.
	pass
```

- `items`의 직접 자식을 순서 항목으로 사용한다. 장식·헤더·버튼은 이 Container 밖에 둔다.
- 포인터는 `get_global_rect()`와 같은 canvas 좌표를 넘긴다.
- 들어 올린 항목은 경계 검색에서 제외한다. 숨겨진 항목은 놓기 기준으로 쓰지 않는다.
- `begin()`은 순서를 바꾸지 않는다. `finish()`에서 한 번 옮긴다.
- 같은 자리에 놓기, 중복 release, 삭제되거나 목록을 떠난 항목은 변경 알림을 보내지 않는다.
- 목록을 다시 그리기 전이나 드래그 취소 시 `cancel()`을 호출한다. 입력 잠금과 연출 복원은 입력 컴포넌트가 맡는다.
- `target_at(item, canvas_pointer)`로 순서를 바꾸지 않고 목적지만 조회할 수 있다. 변화가 없으면 `-1`이다.
- 현재 FLOW는 왼쪽에서 오른쪽으로 읽는 타일 배치용이다. RTL·자동 스크롤·삽입 미리보기는 포함하지 않는다.

## ReorderGesture (노드)

`surface.gui_input`을 `feed(event)`로 전달하면 탭 후보, 스크롤, 집기, 끌기를 구분한다.
`hold_seconds = 0.45`는 긴 누르기, `0.0`은 즉시 집는 손잡이용이다.
터치는 Godot의 마우스 에뮬레이션을 사용한다.

- `surface`에는 입력을 받는 Control을 지정한다.
- `picked`, `dragged(offset)`, `dropped(canvas_pointer)`, `canceled`, `scrolled(offset)`를 보낸다.
- `blocks_selection`이 참인 동안 Button의 `pressed`를 선택 동작으로 해석하지 않는다.
- ScrollContainer의 `scroll_started`를 같은 이름의 메서드에 연결하면 긴 누르기 대기가 취소된다.
- 앱 포커스를 잃거나 입력 표면이 숨겨지면 취소한다. 화면 전환 시 직접 `cancel()`을 호출해도 된다.
- `picked`/`dropped`/`canceled`를 `ListReorder.begin`/`finish`/`cancel`에 연결한다.
- 위치·크기·색 복원은 사용하는 화면이 맡는다. 입력 노드는 애니메이션과 저장을 모른다.

`examples/reorder_demo.tscn`을 F6으로 실행하면 앱 화면 없이 세로 손잡이 목록과 긴 누르기 타일을 확인할 수 있다.

## ArrayOrder

| 함수 | 하는 일 |
| --- | --- |
| `moved(items, from_index, to_index) -> Array` | 항목 하나의 자리를 옮긴 새 배열. 원본은 그대로 |

`to_index`가 범위를 넘으면 양 끝으로 묶는다. `from_index`가 범위 밖이면 복사본을 그대로 돌려준다.

타입이 있는 배열(`Array[T]`)을 넘겨도 `duplicate()`가 타입을 지키므로 그대로 동작한다.
다만 정적 타입은 `Array`로 좁혀지니, 다시 `Array[T]`로 받으려면 `assign()`을 거친다.

```gdscript
static func moved(items: Array[Item], from_index: int, to_index: int) -> Array[Item]:
	var result: Array[Item] = []
	result.assign(ArrayOrder.moved(items, from_index, to_index))
	return result
```

## AspectFit

주어진 사각형 안에서 종횡비를 지키며 가장 크게 들어가는 사각형을 가운데에 놓는다.
카드, 게임 보드, 미리보기처럼 비율은 고정하고 남는 공간을 양쪽에 나눠야 할 때 쓴다.
`aspect_ratio`는 `width / height`다.

| 함수 | 하는 일 |
| --- | --- |
| `centered_rect(available, aspect_ratio) -> Rect2` | `available` 안에 종횡비를 지켜 들어가는 가장 큰 가운데 사각형 |

```gdscript
var board_rect := AspectFit.centered_rect(
	Rect2(Vector2.ZERO, board_stage.size),
	16.0 / 9.0
)
```

## SafeArea

노치와 제스처 바를 피할 여백을 구한다. 여백은 `Vector4`에 좌, 상, 우, 하 순서로 담는다.

`DisplayServer`가 돌려주는 안전 영역은 창 픽셀 단위인데 UI는 viewport 좌표를 쓴다.
두 단위가 다르므로 배율을 곱하지 않으면 stretch를 쓰는 화면에서 여백이 어긋난다.

| 함수 | 하는 일 |
| --- | --- |
| `insets_in_viewport(safe_area, window_size, viewport_size) -> Vector4` | 순수 변환. `DisplayServer`를 부르지 않아 테스트할 수 있다 |
| `is_handheld() -> bool` | Android 또는 iOS인지 |
| `current_insets(viewport_size) -> Vector4` | 지금 화면의 여백. 손에 드는 기기가 아니면 `Vector4.ZERO` |

창 크기를 아직 모르거나(0 이하) 안전 영역이 창 밖까지 걸쳐도 음수 여백을 만들지 않는다.

```gdscript
func _ready() -> void:
	get_tree().root.size_changed.connect(_apply_safe_area)
	_apply_safe_area.call_deferred()

func _apply_safe_area() -> void:
	var insets := SafeArea.current_insets(get_viewport_rect().size)
	margin.offset_left = BASE_MARGIN + insets.x
	margin.offset_top = BASE_MARGIN + insets.y
	margin.offset_right = -(BASE_MARGIN + insets.z)
	margin.offset_bottom = -(BASE_MARGIN + insets.w)
```

## SafeAreaMargin (노드)

`MarginContainer`를 물려받아 안전 영역만큼 자식을 안쪽으로 들여 놓는다.
화면 전체를 감싸는 뿌리 여백이면 이 노드 하나로 끝난다.
창 크기가 바뀔 때마다 다시 계산하므로 화면 회전에도 따라간다.

| | |
| --- | --- |
| `base_margin` | 안전 영역과 무관하게 늘 두는 기본 여백 |
| `apply_left` / `apply_top` / `apply_right` / `apply_bottom` | 어떤 변에 안전 영역을 더할지. 그 변을 직접 다루고 싶으면 꺼 둔다 |
| `insets()` | 마지막으로 적용한 여백 |
| `apply_insets()` | 다시 계산해서 넣는다. 창 크기가 바뀌면 알아서 부르므로 보통 부를 일이 없다 |
| `insets_changed(insets: Vector4)` | 여백이 다시 계산될 때. 상단 알림이나 하단 시트가 같은 값을 나눠 쓸 때 잇는다 |

여백은 theme constant(`margin_left` 등)로 넣는다. `MarginContainer`의 본래 방식이다.
`offset_*`으로 직접 여백을 다루는 화면이라면 이 노드 대신 `SafeArea.current_insets()`를 쓴다.

## KeyboardInsetAvoider (노드)

가상 키보드가 덮은 만큼 자기 자신을 위로 올려, 포커스된 입력창이 가려지지 않게 한다.
자식으로 `LineEdit`이나 `TextEdit`을 두는 화면(편집 화면, 하단 시트)에 씌운다.

| | |
| --- | --- |
| `keyboard_padding` | 입력창 아래끝과 키보드 사이에 둘 틈 (기본 24) |
| `top_padding` | 위끝이 화면 밖으로 밀려나지 않을 최소 여백 (기본 16) |
| `avoid_target` | 지정하면 포커스된 입력창 대신 이 노드 전체를 올린다 (하단 시트용) |

가상 키보드를 지원하지 않는 플랫폼에서는 `_process`를 아예 끈다.
데스크톱에서 높이를 조회하면 매 frame 경고가 나고 IME 입력을 방해하기 때문이다.
노드가 원점이 아닌 곳에 있어도 기존 X와 기준 Y를 보존하고, 키보드가 닫히거나 노드가
숨겨지면 그 자리로 돌아온다.

계산만 따로 부를 수도 있다.

| 함수 | 하는 일 |
| --- | --- |
| `scaled_keyboard_height(keyboard_height, window_size, viewport_size) -> float` | 창 픽셀 단위의 키보드 높이를 viewport 좌표로 |
| `required_shift(focused_bottom, focused_top, keyboard_height, viewport_height, bottom_padding := 24.0, minimum_top := 16.0) -> float` | 얼마나 올려야 하는지. 위끝이 밀려나지 않는 선에서 멈춘다 |

## 테스트

`MobileFoundationChecks.run(report)`가 모듈 전체의 경계값을 검사한다.
어떤 harness에도 매이지 않는다. `report`는 `func(passed: bool, description: String) -> void` 형태의 `Callable`이고,
쓰는 쪽에서 자기 harness의 단언 함수를 넘기면 결과가 그대로 흘러 들어간다.

```gdscript
extends TestCase

func run_tests() -> void:
	MobileFoundationChecks.run(
		func(passed: bool, description: String) -> void: check(passed, description)
	)
```

harness가 없다면 print만 하는 Callable을 넘겨도 된다.

```gdscript
MobileFoundationChecks.run(
	func(passed: bool, description: String) -> void:
		print(("PASS: " if passed else "FAIL: ") + description)
)
```

이 프로젝트에서는 `tests/mobile_foundation_smoke.gd`가 그 다리다.
`res://tests/tests.tscn`을 헤드리스로 돌리면 나머지 테스트와 함께 실행된다.

## 모듈 경계

앱의 백업 경로, 테마·문구, 학습 판정과 카드 애니메이션은 이 모듈에 포함하지 않는다. 해당 기능은 `src/storage/`와 `src/main/`에서 관리한다. 새 기능을 옮길 때도 앱 타입과 `res://src/` 참조 없이 독립 예제를 실행할 수 있어야 한다.
