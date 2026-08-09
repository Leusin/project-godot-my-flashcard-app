class_name WrongTallyView
extends Control

const STROKE_COLOR := Color(0.12, 0.12, 0.12, 1)
const STROKE_WIDTH := 3.5
const STROKE_SPACING := 8.0
const GROUP_GAP := 12.0
const MARK_TOP := 8.0
const MARK_BOTTOM := 34.0

var wrong_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_update_size()


func set_count(value: int) -> void:
	wrong_count = maxi(value, 0)
	tooltip_text = "오답 %d회" % wrong_count
	_update_size()
	queue_redraw()


func _draw() -> void:
	var remaining := wrong_count
	var group_index := 0
	while remaining > 0:
		var marks_in_group := mini(remaining, 5)
		_draw_group(group_index, marks_in_group)
		remaining -= marks_in_group
		group_index += 1


func _draw_group(group_index: int, marks_in_group: int) -> void:
	var group_x := group_index * (STROKE_SPACING * 3.0 + GROUP_GAP)
	var vertical_count := mini(marks_in_group, 4)
	for stroke_index in vertical_count:
		var stroke_x := group_x + stroke_index * STROKE_SPACING + STROKE_WIDTH
		draw_line(
			Vector2(stroke_x, MARK_TOP),
			Vector2(stroke_x, MARK_BOTTOM),
			STROKE_COLOR,
			STROKE_WIDTH,
			true
		)

	if marks_in_group == 5:
		draw_line(
			Vector2(group_x, MARK_BOTTOM - 2.0),
			Vector2(group_x + STROKE_SPACING * 3.0 + STROKE_WIDTH * 2.0, MARK_TOP + 2.0),
			STROKE_COLOR,
			STROKE_WIDTH,
			true
		)


func _update_size() -> void:
	var group_count := ceili(wrong_count / 5.0)
	var width := 0.0
	if group_count > 0:
		width = group_count * (STROKE_SPACING * 3.0 + STROKE_WIDTH * 2.0)
		width += (group_count - 1) * (GROUP_GAP - STROKE_WIDTH * 2.0)
	custom_minimum_size = Vector2(width, 42.0)
