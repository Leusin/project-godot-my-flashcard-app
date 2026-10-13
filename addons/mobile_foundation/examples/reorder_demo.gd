extends MarginContainer

# 앱 데이터 없이 입력과 재정렬 컴포넌트만 시험하는 독립 예제.
@onready var status: Label = $Content/Status
@onready var rows: VBoxContainer = $Content/Rows
@onready var tiles: HFlowContainer = $Content/Tiles


func _ready() -> void:
	_build_list(rows, ListReorder.Layout.VERTICAL, 3, 0.0)
	_build_list(tiles, ListReorder.Layout.FLOW, 6, 0.45)


func _build_list(container: Container, layout: ListReorder.Layout, count: int, hold: float) -> void:
	var reorder := ListReorder.new()
	reorder.items = container
	reorder.layout = layout
	add_child(reorder)
	reorder.reordered.connect(
		func(from_index: int, to_index: int) -> void:
			status.text = "%d → %d 이동 완료" % [from_index + 1, to_index + 1]
	)
	for index in count:
		var button := Button.new()
		button.text = ("바로 끌기 %d" if hold == 0.0 else "꾹 눌러 끌기 %d") % (index + 1)
		button.custom_minimum_size = Vector2(190, 84)
		container.add_child(button)
		var gesture := ReorderGesture.new()
		gesture.surface = button
		gesture.hold_seconds = hold
		button.add_child(gesture)
		var rest := [Vector2.ZERO]
		gesture.picked.connect(
			func() -> void:
				rest[0] = button.position
				button.z_index = 1
				button.modulate = Color(0.7, 0.85, 1.0)
				reorder.begin(button)
				status.text = "끌어서 원하는 항목 앞이나 뒤에 놓으세요."
		)
		gesture.dragged.connect(func(offset: Vector2) -> void: button.position = rest[0] + offset)
		gesture.dropped.connect(
			func(pointer: Vector2) -> void:
				button.position = rest[0]
				button.z_index = 0
				button.modulate = Color.WHITE
				reorder.finish(button, pointer)
		)
		gesture.canceled.connect(
			func() -> void:
				button.position = rest[0]
				button.z_index = 0
				button.modulate = Color.WHITE
				reorder.cancel()
				status.text = "이동 취소"
		)
		button.gui_input.connect(
			func(event: InputEvent) -> void:
				var was_dragging := gesture.state == ReorderGesture.State.DRAGGING
				gesture.feed(event)
				if was_dragging or gesture.state == ReorderGesture.State.DRAGGING:
					button.accept_event()
		)
		button.pressed.connect(
			func() -> void:
				if not gesture.blocks_selection:
					status.text = "%s: 짧은 탭" % button.text
		)
